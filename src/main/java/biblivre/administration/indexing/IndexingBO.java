/*******************************************************************************
 * Este arquivo é parte do Biblivre5.
 *
 * Biblivre5 é um software livre; você pode redistribuí-lo e/ou
 * modificá-lo dentro dos termos da Licença Pública Geral GNU como
 * publicada pela Fundação do Software Livre (FSF); na versão 3 da
 * Licença, ou (caso queira) qualquer versão posterior.
 *
 * Este programa é distribuído na esperança de que possa ser  útil,
 * mas SEM NENHUMA GARANTIA; nem mesmo a garantia implícita de
 * MERCANTIBILIDADE OU ADEQUAÇÃO PARA UM FIM PARTICULAR. Veja a
 * Licença Pública Geral GNU para maiores detalhes.
 *
 * Você deve ter recebido uma cópia da Licença Pública Geral GNU junto
 * com este programa, Se não, veja em <http://www.gnu.org/licenses/>.
 *
 * @author Alberto Wagner <alberto@biblivre.org.br>
 * @author Danniel Willian <danniel@biblivre.org.br>
 ******************************************************************************/
package biblivre.administration.indexing;

import biblivre.cataloging.AutocompleteDTO;
import biblivre.cataloging.Fields;
import biblivre.cataloging.FormTabSubfieldDTO;
import biblivre.cataloging.RecordBO;
import biblivre.cataloging.RecordDTO;
import biblivre.cataloging.enums.RecordType;
import biblivre.core.AbstractBO;
import biblivre.core.utils.TextUtils;
import biblivre.marc.MarcDataReader;
import biblivre.marc.MarcUtils;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.marc4j.marc.DataField;
import org.marc4j.marc.Record;
import org.marc4j.marc.Subfield;

public class IndexingBO extends AbstractBO {
    Map<String, RecordBO> recordBOs = new HashMap<>();

    private IndexingDAO indexingDAO;

    private String[] nonfillingCharactersInIndicator1 = new String[] {"130", "630", "730", "740"};
    private String[] nonfillingCharactersInIndicator2 = new String[] {"240", "243", "245", "830"};

    private volatile boolean reindexingBiblioBase = false;
    private volatile boolean reindexingAuthoritiesBase = false;
    private volatile boolean reindexingVocabularyBase = false;

    public void reindex(RecordType recordType, RecordDTO dto) {
        synchronized (this) {
            List<IndexingGroupDTO> indexingGroups = IndexingGroups.getGroups(recordType);
            List<FormTabSubfieldDTO> autocompleteSubfields =
                    Fields.getAutocompleteSubFields(recordType);

            List<IndexingDTO> indexes = new ArrayList<>();
            List<IndexingDTO> sortIndexes = new ArrayList<>();
            List<AutocompleteDTO> autocompleteIndexes = new ArrayList<>();

            this.populateIndexes(dto, indexingGroups, indexes, sortIndexes);
            this.populateAutocompleteIndexes(dto, autocompleteSubfields, autocompleteIndexes);

            this.deleteIndexes(recordType, dto);
            this.indexingDAO.insertIndexes(recordType, indexes);
            this.indexingDAO.insertSortIndexes(recordType, sortIndexes);
            this.indexingDAO.insertAutocompleteIndexes(recordType, autocompleteIndexes);
        }
    }

    public void reindex(RecordType recordType) {
        if (this.getLockState(recordType)) {
            return;
        }

        synchronized (this) {
            this.toggleLockState(recordType, true);

            try {
                this.clearIndexes(recordType);

                List<IndexingGroupDTO> indexingGroups = IndexingGroups.getGroups(recordType);
                List<FormTabSubfieldDTO> autocompleteSubfields =
                        Fields.getAutocompleteSubFields(recordType);

                RecordBO rbo = recordBOs.get(recordType.name());

                int recordCount = rbo.count();
                int limit = 30;

                for (int offset = 0; offset < recordCount; offset += limit) {
                    // if (this.logger.isDebugEnabled()) {
                    // this.logger.debug("Reindexing offsets from " + offset + " to " + (offset +
                    // limit));
                    // }

                    List<RecordDTO> records = rbo.list(offset, limit);

                    List<IndexingDTO> indexes = new ArrayList<>();
                    List<IndexingDTO> sortIndexes = new ArrayList<>();
                    List<AutocompleteDTO> autocompleteIndexes = new ArrayList<>();

                    for (RecordDTO dto : records) {
                        this.populateIndexes(dto, indexingGroups, indexes, sortIndexes);
                        this.populateAutocompleteIndexes(
                                dto, autocompleteSubfields, autocompleteIndexes);
                    }

                    this.indexingDAO.insertIndexes(recordType, indexes);
                    this.indexingDAO.insertSortIndexes(recordType, sortIndexes);
                    this.indexingDAO.insertAutocompleteIndexes(recordType, autocompleteIndexes);
                }

                this.indexingDAO.reindexDatabase(recordType);
            } finally {
                this.toggleLockState(recordType, false);
            }
        }
    }

    public void reindexAutocompleteFixedTable(
            RecordType recordType, String datafield, String subfield, List<String> phrases) {
        this.indexingDAO.reindexAutocompleteFixedTable(recordType, datafield, subfield, phrases);
    }

    private void populateIndexes(
            RecordDTO dto,
            List<IndexingGroupDTO> indexingGroups,
            List<IndexingDTO> indexes,
            List<IndexingDTO> sortIndexes) {
        Record record = MarcUtils.iso2709ToRecord(dto.getIso2709());
        MarcDataReader marcDataReader = new MarcDataReader(record);

        //		System.out.println((Runtime.getRuntime().totalMemory() -
        // Runtime.getRuntime().freeMemory()) + " free: " + Runtime.getRuntime().freeMemory());

        IndexingDTO index;
        IndexingDTO sortIndex;
        String datafieldTag;
        List<DataField> datafields;
        List<Subfield> subfields;
        String phrase;
        boolean charsToIgnoreSet;

        int datafieldId = 0;

        index = new IndexingDTO();
        index.setIndexingGroupId(0);
        index.setRecordId(dto.getId());
        index.addWord(String.valueOf(dto.getId()), datafieldId);

        indexes.add(index);

        // For each indexing group
        for (IndexingGroupDTO ig : indexingGroups) {
            index = new IndexingDTO();
            index.setIndexingGroupId(ig.getId());
            index.setRecordId(dto.getId());

            if (ig.getId() != 0) {
                sortIndex = new IndexingDTO();
                sortIndex.setIndexingGroupId(ig.getId());
                sortIndex.setRecordId(dto.getId());
                charsToIgnoreSet = false;
            } else {
                sortIndex = null;
                charsToIgnoreSet = true;
            }

            // For each datafield in indexing group
            for (Pair<String, List<Character>> pair : ig.getDatafieldsArray()) {
                datafieldTag = pair.getLeft();

                // Get all datafields from record
                datafields = marcDataReader.getDataFields(datafieldTag);

                // For each one of those datafields
                for (DataField datafield : datafields) {
                    datafieldId++;

                    // For each subfield in indexing group
                    for (Character subfieldTag : pair.getRight()) {
                        // Get all the subfields from datafield
                        subfields = datafield.getSubfields(subfieldTag);

                        for (Subfield subfield : subfields) {
                            phrase = TextUtils.preparePhrase(subfield.getData());
                            index.addWords(TextUtils.prepareWords(phrase), datafieldId);
                            // index.addWord(phrase);

                            if (sortIndex != null) {
                                sortIndex.appendToPhrase(phrase);
                            }
                        }
                    }

                    // Some datafields have nonfillings characters, based on indicator 1 or 2
                    if (!charsToIgnoreSet && sortIndex.getPhraseLength() > 0) {
                        char indicator = '0';
                        if (ArrayUtils.contains(
                                this.nonfillingCharactersInIndicator1, datafieldTag)) {
                            indicator = datafield.getIndicator1();
                        } else if (ArrayUtils.contains(
                                this.nonfillingCharactersInIndicator2, datafieldTag)) {
                            indicator = datafield.getIndicator2();
                        }

                        if (indicator >= '1' && indicator <= '9') {
                            sortIndex.setIgnoreCharsCount(
                                    Integer.valueOf(Character.toString(indicator)));
                        }

                        charsToIgnoreSet = true;
                    }
                }
            }

            if (index.getCount() > 0) {
                indexes.add(index);
            }

            if (sortIndex != null) {
                sortIndexes.add(sortIndex);
            }
        }
    }

    private void populateAutocompleteIndexes(
            RecordDTO dto,
            List<FormTabSubfieldDTO> autocompleteSubfields,
            List<AutocompleteDTO> autocompleteIndexes) {
        Record record = MarcUtils.iso2709ToRecord(dto.getIso2709());

        MarcDataReader marcDataReader = new MarcDataReader(record);
        AutocompleteDTO autocomplete;
        List<DataField> datafields;
        List<Subfield> subfields;
        String phrase;

        for (FormTabSubfieldDTO autocompleteSubfield : autocompleteSubfields) {
            datafields = marcDataReader.getDataFields(autocompleteSubfield.getDatafield());

            for (DataField datafield : datafields) {
                subfields = datafield.getSubfields(autocompleteSubfield.getSubfield().charAt(0));

                for (Subfield subfield : subfields) {
                    phrase = subfield.getData();

                    if (StringUtils.isBlank(phrase)) {
                        continue;
                    }

                    autocomplete = new AutocompleteDTO();

                    autocomplete.setRecordId(dto.getId());
                    autocomplete.setDatafield(autocompleteSubfield.getDatafield());
                    autocomplete.setSubfield(autocompleteSubfield.getSubfield());
                    autocomplete.setPhrase(phrase);

                    autocompleteIndexes.add(autocomplete);
                }
            }
        }
    }

    private void toggleLockState(RecordType recordType, boolean state) {
        switch (recordType) {
            case BIBLIO:
                this.reindexingBiblioBase = state;
                break;
            case AUTHORITIES:
                this.reindexingAuthoritiesBase = state;
                break;
            case VOCABULARY:
                this.reindexingVocabularyBase = state;
                break;
            default:
                break;
        }
    }

    private boolean getLockState(RecordType recordType) {
        switch (recordType) {
            case BIBLIO:
                return this.reindexingBiblioBase;
            case AUTHORITIES:
                return this.reindexingAuthoritiesBase;
            case VOCABULARY:
                return this.reindexingVocabularyBase;
            default:
                return false;
        }
    }

    public int countIndexed(RecordType recordType) {
        return this.indexingDAO.countIndexed(recordType);
    }

    public int[] getReindexProgress(RecordType recordType) {
        int progress[] = new int[2];

        RecordBO rbo = recordBOs.get(recordType.name());

        progress[0] = this.countIndexed(recordType);
        progress[1] = rbo.count();

        return progress;
    }

    public boolean isIndexOutdated() {
        Stream<RecordBO> stream = recordBOs.values().stream();

        return stream.anyMatch(this::_hasOutdatedIndexCount);
    }

    private boolean _hasOutdatedIndexCount(RecordBO recordBO) {
        int indexedCount = this.indexingDAO.countIndexed(recordBO.getRecordType());

		int persistedCount = recordBO.count();

		return indexedCount != persistedCount;
    }

    private void clearIndexes(RecordType recordType) {
        this.indexingDAO.clearIndexes(recordType);
    }

    public boolean deleteIndexes(RecordType recordType, RecordDTO dto) {
        return this.indexingDAO.deleteIndexes(recordType, dto);
    }

    public List<String> searchExactTerm(RecordType recordType, int indexingGroupId, String term) {
        List<String> terms = new ArrayList<>();
        terms.add(term);
        return this.indexingDAO.searchExactTerms(recordType, indexingGroupId, terms);
    }

    public List<String> searchExactTerms(
            RecordType recordType, int indexingGroupId, List<String> terms) {
        return this.indexingDAO.searchExactTerms(recordType, indexingGroupId, terms);
    }

    public void setRecordBOs(Map<String, RecordBO> recordBOs) {
        this.recordBOs = recordBOs;
    }

    public void setIndexingDAO(IndexingDAO indexingDAO) {
        this.indexingDAO = indexingDAO;
    }
}
