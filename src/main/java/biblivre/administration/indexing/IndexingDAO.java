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

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;

import biblivre.cataloging.AutocompleteDTO;
import biblivre.cataloging.RecordDTO;
import biblivre.cataloging.enums.RecordType;
import biblivre.core.AbstractDAO;
import biblivre.core.PreparedStatementUtil;
import biblivre.core.exceptions.DAOException;
import biblivre.core.utils.CheckedFunction;
import biblivre.core.utils.TextUtils;

public class IndexingDAO extends AbstractDAO {
	
	private static final String _CLEAR_INDEXES_AUTOCOMPLETE_SQL_TPL =
		"DELETE FROM %s_idx_autocomplete WHERE record_id is not null";

	private static final String _CLEAR_INDEXES_SORT_SQL_TPL =
		"TRUNCATE TABLE %s_idx_sort";

	private static final String _CLEAR_INDEXES_FIELDS_SQL_TPL =
		"TRUNCATE TABLE %s_idx_fields";

	private static final String _SEARCH_EXTRACT_TERMS_SQL_TPL =
		"SELECT phrase FROM %s_idx_sort "
		+ "WHERE indexing_group_id = ? AND phrase in (%s)";

	private static final String _DELETE_INDEXES_AUTOCOMPLETE_SQL_TPL =
		"DELETE FROM %s_idx_autocomplete "
		+ "WHERE record_id = ?";

	private static final String _DELETE_INDEX_SORT_SQL_TPL =
		"DELETE FROM %s_idx_sort WHERE record_id = ?";

	private static final String _DELETE_INDEXES_FIELDS_SQL_TPL =
		"DELETE FROM %s_idx_fields WHERE record_id = ?";

	private static final String _REINDEX_AUTOCOMPLETE_FIXED_TABLE_INSERT_SQL_TPL =
		"INSERT INTO %s_idx_autocomplete "
		+ "(datafield, subfield, word, phrase, record_id) "
		+ "VALUES (?, ?, ?, ?, null)";

	private static final String _REINDEX_AUTOCOMPLETE_FIXED_TABLE_DELETE_SQL_TPL =
		"DELETE FROM %s_idx_autocomplete "
		+ "WHERE datafield = ? and subfield = ? and record_id is null";

	private static final String _INSERT_AUTOCOMPLETE_SQL_TPL =
		"INSERT INTO %s_idx_autocomplete "
		+ "(datafield, subfield, word, phrase, record_id) "
		+ "VALUES (?, ?, ?, ?, ?)";

	private static final String _INSERT_SORT_INDEXES_SQL_TPL =
		"INSERT INTO %s_idx_sort "
		+ "(record_id, indexing_group_id, phrase, ignore_chars_count) "
		+ "VALUES (?, ?, ?, ?)";

	private static final String _INSERT_INDEXES_SQL_TPL = 
		"INSERT INTO %s_idx_fields "
		+ "(record_id, indexing_group_id, word, datafield) "
		+ "VALUES (?, ?, ?, ?)";

	private static final String _COUNT_INDEXED_SQL_TPL =
		"SELECT count(DISTINCT record_id) as total FROM %s_idx_sort";

	public static IndexingDAO getInstance(String schema) {
		return (IndexingDAO) AbstractDAO.getInstance(IndexingDAO.class, schema);
	}

	public Integer countIndexed(RecordType recordType) {
		String sql = String.format(
				_COUNT_INDEXED_SQL_TPL, recordType.toString());

		return fetchOne(rs -> rs.getInt("total"), sql);
	}

	public void clearIndexes(RecordType recordType) {
		CheckedFunction<PreparedStatement, PreparedStatement> noop = __ -> __;

		executeQuery(
			noop, String.format(_CLEAR_INDEXES_FIELDS_SQL_TPL, recordType));

		executeQuery(
			noop, String.format(_CLEAR_INDEXES_SORT_SQL_TPL, recordType));

		executeQuery(
			noop,
			String.format(_CLEAR_INDEXES_AUTOCOMPLETE_SQL_TPL, recordType));
	}

	public void insertIndexes(
		RecordType recordType, List<IndexingDTO> indexes) {

		int total = indexes.stream()
			.mapToInt(IndexingDTO::getCount)
			.sum();

		if (total == 0) {
			return;
		}

		String sql = String.format(_INSERT_INDEXES_SQL_TPL, recordType);

		Collection<Object[]> quartets = _prepareParameters(indexes);

		executeBatchUpdate(
			quartets, Object[].class, sql, q -> q[0], q -> q[1], q -> q[2],
			q -> q[3]);
	}

	public void insertSortIndexes(
		RecordType recordType, List<IndexingDTO> sortIndexes) {

		if (sortIndexes.size() == 0) {
			return;
		}

		String sql = String.format(
			_INSERT_SORT_INDEXES_SQL_TPL, recordType.toString());

		executeBatchUpdate(
			sortIndexes, IndexingDTO.class, sql, IndexingDTO::getRecordId,
			IndexingDTO::getIndexingGroupId, IndexingDTO::getPhrase,
			IndexingDTO::getIgnoreCharsCount);
	}

	public void insertAutocompleteIndexes(
			RecordType recordType, List<AutocompleteDTO> autocompleteIndexes) {

		if (autocompleteIndexes.size() == 0) {
			return;
		}

		String sql = String.format(
			_INSERT_AUTOCOMPLETE_SQL_TPL, recordType.toString());

		executeBatchUpdate((pst, autocomplete) -> {
			final Integer recordId = autocomplete.getRecordId();
			final String datafield = autocomplete.getDatafield();
			final String subfield = autocomplete.getSubfield();
			final String phrase = autocomplete.getPhrase();

			for (String word : TextUtils.prepareAutocomplete(phrase)) {
				if (StringUtils.isBlank(word) || word.length() < 2) {
					continue;
				}

				PreparedStatementUtil.setAllParameters(
					pst, datafield, subfield, word, phrase, recordId);
			}
		}, autocompleteIndexes, sql);
	}

	public void reindexAutocompleteFixedTable(
		RecordType recordType, String datafield, String subfield,
		List<String> phrases) {

		String deleteSql = String.format(
			_REINDEX_AUTOCOMPLETE_FIXED_TABLE_DELETE_SQL_TPL, recordType);

		String insertSql = String.format(
			_REINDEX_AUTOCOMPLETE_FIXED_TABLE_INSERT_SQL_TPL, recordType);

		onTransactionContext(con -> {
			executeUpdate(deleteSql, datafield, subfield);

			executeBatchUpdate((pst, phrase) -> {
				for (String word : TextUtils.prepareAutocomplete(phrase)) {
					if (StringUtils.isBlank(word) || word.length() < 2) {
						continue;
					}

					PreparedStatementUtil.setAllParameters(
						pst, datafield, subfield, word, phrase);
				}
			}, phrases, insertSql);
		});
	}

	public boolean deleteIndexes(RecordType recordType, RecordDTO dto) {
		onTransactionContext(con -> {
			executeUpdate(
				String.format(_DELETE_INDEXES_FIELDS_SQL_TPL, recordType),
				dto.getId());

			executeUpdate(
				String.format(_DELETE_INDEX_SORT_SQL_TPL, recordType),
				dto.getId());

			executeUpdate(
				String.format(_DELETE_INDEXES_AUTOCOMPLETE_SQL_TPL, recordType),
				dto.getId());
		});

		return true;
	}

	public void reindexDatabase(RecordType recordType) {
		Connection con = null;
		try {
			con = this.getConnection();

			Statement st = con.createStatement();

			st.execute("REINDEX TABLE " + recordType + "_idx_fields");
			st.execute("REINDEX TABLE " + recordType + "_idx_sort");
			st.execute("ANALYZE " + recordType + "_idx_fields");
			st.execute("ANALYZE " + recordType + "_idx_sort");
		} catch (Exception e) {
			throw new DAOException(e);
		} finally {
			this.closeConnection(con);
		}
	}

	public List<String> searchExactTerms(
		RecordType recordType, int indexingGroupId, List<String> terms) {

		String sql = _getExtractTermsSql(recordType, terms);

		Object[] parameters = _prepareParameters(indexingGroupId, terms);

		return listWith(
			rs -> rs.getString("phrase"), sql.toString(), parameters);
	}

	private Object[] _prepareParameters(
		int indexingGroupId, List<String> terms) {

		List<String> parameters = new ArrayList<>();

		parameters.add(String.valueOf(indexingGroupId));

		parameters.addAll(terms);

		return parameters.toArray();
	}

	private Collection<Object[]> _prepareParameters(List<IndexingDTO> indexes) {
		Collection<Object[]> quartets = new ArrayList<>();

		for (IndexingDTO index : indexes) {
			Map<Integer, Set<String>> wordsGroups = index.getWords();
			for (Integer key : wordsGroups.keySet()) {
				Collection<String> words = wordsGroups.get(key);
				for (String word : words) {
					quartets.add(
						new Object[] {
							index.getRecordId(), index.getIndexingGroupId(),
							word, key});
				}
			}
		}
		return quartets;
	}

	private String _getExtractTermsSql(
		RecordType recordType, List<String> terms) {

		return String.format(
			_SEARCH_EXTRACT_TERMS_SQL_TPL, recordType.toString(),
			StringUtils.repeat("?", ", ", terms.size()));
	}
}
