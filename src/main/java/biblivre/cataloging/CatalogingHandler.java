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
package biblivre.cataloging;

import biblivre.administration.indexing.IndexingGroupDTO;
import biblivre.administration.indexing.IndexingGroups;
import biblivre.cataloging.enums.AutocompleteType;
import biblivre.cataloging.enums.RecordDatabase;
import biblivre.cataloging.enums.RecordType;
import biblivre.cataloging.search.SearchDTO;
import biblivre.cataloging.search.SearchQueryDTO;
import biblivre.core.AbstractHandler;
import biblivre.core.DTOCollection;
import biblivre.core.ExtendedRequest;
import biblivre.core.ExtendedResponse;
import biblivre.core.auth.AuthorizationPoints;
import biblivre.core.enums.ActionResult;
import biblivre.core.exceptions.ValidationException;
import biblivre.core.file.DiskFile;
import biblivre.marc.MaterialType;
import biblivre.marc.RecordStatus;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.json.JSONException;
import org.marc4j.MarcReader;
import org.marc4j.marc.Record;

public abstract class CatalogingHandler extends AbstractHandler {

    protected RecordType recordType;
    protected MaterialType defaultMaterialType;

    protected CatalogingHandler(RecordType recordType, MaterialType defaultMaterialType) {
        this.recordType = recordType;
        this.defaultMaterialType = defaultMaterialType;
    }

    public void search(ExtendedRequest request, ExtendedResponse response) {
        SearchDTO search = this.searchHelper(request, response);

        if (search.size() == 0) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.no_records_found");
        }

        if (CollectionUtils.isEmpty(search)) {
            return;
        }

        List<IndexingGroupDTO> groups =
                IndexingGroups.getGroups(request.getSchema(), this.recordType);

        this.json.put("search", search.toJSONObject());

        for (IndexingGroupDTO group : groups) {
            this.json.accumulate("indexing_groups", group.toJSONObject());
        }
    }

    public SearchDTO searchHelper(ExtendedRequest request, ExtendedResponse response) {

        String searchParameters = request.getString("search_parameters");

        SearchQueryDTO searchQuery = new SearchQueryDTO(searchParameters);

        AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

        String schema = request.getSchema();

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);

        return bo.search(searchQuery, recordType, authorizationPoints);
    }

    public void paginate(ExtendedRequest request, ExtendedResponse response) {
        SearchDTO search = this.paginateHelper(request, response, this);

        List<IndexingGroupDTO> groups =
                IndexingGroups.getGroups(request.getSchema(), this.recordType);

        if (CollectionUtils.isEmpty(search)) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.no_records_found");
            return;
        }

        try {
            this.json.put("search", search.toJSONObject());

            for (IndexingGroupDTO group : groups) {
                this.json.accumulate("indexing_groups", group.toJSONObject());
            }
        } catch (JSONException e) {
        }
    }

    public SearchDTO paginateHelper(
            ExtendedRequest request, ExtendedResponse response, AbstractHandler handler) {
        String schema = request.getSchema();
        Integer searchId = request.getInteger("search_id", null);
        Integer indexingGroup = request.getInteger("indexing_group", 0);
        Integer sort =
                request.getInteger(
                        "sort", IndexingGroups.getDefaultSortableGroupId(schema, this.recordType));
        Integer page = request.getInteger("page", 1);

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);

        SearchDTO search = bo.getSearch(searchId);

        if (search == null) {
            handler.setMessage(ActionResult.WARNING, "cataloging.error.no_records_found");
            return null;
        }

        if (search.getQuery().getDatabase() == RecordDatabase.PRIVATE) {
            AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

            this.authorize(
                    "cataloging.bibliographic",
                    "private_database_access",
                    schema,
                    authorizationPoints);
        }

        search.getPaging().setPage(page);
        search.setSort(sort);
        search.setIndexingGroup(indexingGroup);

        bo.paginateSearch(search);

        if (search.size() == 0) {
            bo.search(search);
        }

        if (search.size() == 0) {
            handler.setMessage(ActionResult.WARNING, "cataloging.error.no_records_found");
        }

        return search;
    }

    public void open(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();

        Integer id = request.getInteger("id", null);

        AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

        if (id == null) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.record_not_found");

            return;
        }

        RecordBO recordBO = RecordBO.getInstance(schema, recordType);

        RecordDTO dto = recordBO.open(id, authorizationPoints);

        if (dto == null) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.record_not_found");

            return;
        }

        this.json.put("data", dto.toJSONObject());
    }

    public void save(ExtendedRequest request, ExtendedResponse response) {

        String schema = request.getSchema();

        RecordBO recordBO = RecordBO.getInstance(schema, this.recordType);

        Integer id = request.getInteger("id");

        boolean isNew = id == 0;

        RecordDTO recordDTO = isNew ? this.createRecordDTO(null) : recordBO.get(id);

        if (recordDTO == null) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.record_not_found");

            return;
        }

        hydrateRecord(recordDTO, request);

        AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

        int loggedUserId = request.getLoggedUserId();

        boolean success = recordBO.saveOrUpdate(recordDTO, loggedUserId, authorizationPoints);

        if (!success) {
            this.setMessage(ActionResult.WARNING, "cataloging.record.error.save");

            return;
        }

        _setSuccessMessage(isNew);

        this.json.put("data", recordDTO.toJSONObject());
    }

    private void hydrateRecord(RecordDTO recordDTO, ExtendedRequest request) {
        MaterialType materialType =
                request.getEnum(MaterialType.class, "material_type", this.defaultMaterialType);

        recordDTO.setMaterialType(materialType);

        RecordDatabase recordDatabase = request.getEnum(RecordDatabase.class, "database");

        recordDTO.setRecordDatabase(recordDatabase);

        RecordConvertion recordConvertion = request.getEnum(RecordConvertion.class, "from");

        String recordData = request.getString("data");

        boolean isNew = request.getInteger("id") == 0;

        RecordStatus recordStatus = RecordStatus.fromNewStatus(isNew);

        MarcReader marcReader = recordConvertion.getReader(recordData, materialType, recordStatus);

        recordDTO.setRecord(marcReader.next());

        recordDTO.setSchema(request.getSchema());

        this.hydrateRecordImpl(recordDTO, request);
    }

    private void _setSuccessMessage(boolean isNew) {
        if (isNew) {
            this.setMessage(ActionResult.SUCCESS, "cataloging.record.success.save");
        } else {
            this.setMessage(ActionResult.SUCCESS, "cataloging.record.success.update");
        }
    }

    protected void hydrateRecordImpl(RecordDTO dto, ExtendedRequest request) {}
    ;

    protected void afterConvert(ExtendedRequest request, RecordDTO dto) {}

    public void delete(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        Integer id = request.getInteger("id", null);
        RecordDatabase recordDatabase = request.getEnum(RecordDatabase.class, "database");

        if (id == null) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.record_not_found");
            return;
        }

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);
        RecordDTO dto = bo.get(id);

        if (dto == null || dto.getRecordDatabase() != recordDatabase) {
            this.setMessage(ActionResult.WARNING, "cataloging.error.record_not_found");
            return;
        }

        if (recordDatabase == null) {
            ValidationException ex = new ValidationException("cataloging.error.invalid_database");
            this.setMessage(ex);
            return;
        }

        if (recordDatabase == RecordDatabase.PRIVATE) {
            AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

            this.authorize(
                    "cataloging.bibliographic",
                    "private_database_access",
                    schema,
                    authorizationPoints);
        }

        dto.setModifiedBy(request.getLoggedUserId());
        boolean success = false;
        if (recordDatabase == RecordDatabase.TRASH) {
            success = bo.delete(dto);
        } else {
            Set<Integer> ids = new TreeSet<Integer>();
            ids.add(dto.getId());
            success = bo.moveRecords(ids, request.getLoggedUserId(), RecordDatabase.TRASH);
        }

        if (success) {
            this.setMessage(ActionResult.SUCCESS, "cataloging.record.success.delete");
        } else {
            this.setMessage(ActionResult.WARNING, "cataloging.record.error.delete");
        }
    }

    public void convert(ExtendedRequest request, ExtendedResponse response) {
        String data = request.getString("data");

        RecordConvertion from = request.getEnum(RecordConvertion.class, "from");

        MaterialType materialType =
                request.getEnum(MaterialType.class, "material_type", this.defaultMaterialType);

        Integer id = request.getInteger("id");

        boolean isNew = id == 0;

        RecordDTO dto = this.createRecordDTO(request);

        dto.setMaterialType(materialType);

        Record record = null;

        try {
            MarcReader marcReader =
                    from.getReader(data, materialType, RecordStatus.fromNewStatus(isNew));

            record = marcReader.next();

            dto.setRecord(record);
        } catch (Exception e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_parameters");
            return;
        }

        this.afterConvert(request, dto);

        try {
            this.json.put("data", dto.toJSONObject());
        } catch (Exception e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
        }
    }

    public void itemCount(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        RecordDatabase recordDatabase = request.getEnum(RecordDatabase.class, "database");

        if (recordDatabase == null) {
            ValidationException ex = new ValidationException("cataloging.error.invalid_database");
            this.setMessage(ex);
            return;
        }

        if (recordDatabase == RecordDatabase.PRIVATE) {
            AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

            this.authorize(
                    "cataloging.bibliographic",
                    "private_database_access",
                    schema,
                    authorizationPoints);
        }

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);
        SearchQueryDTO query = new SearchQueryDTO(recordDatabase);
        SearchDTO dto = new SearchDTO(this.recordType);
        dto.setQuery(query);

        int count = bo.count(dto);

        try {
            this.json.put("count", count);
        } catch (JSONException e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
        }
    }

    public void moveRecords(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();

        String[] idList = request.getString("id_list").split(",");
        RecordDatabase recordDatabase = request.getEnum(RecordDatabase.class, "database");

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);

        if (recordDatabase == null) {
            ValidationException ex = new ValidationException("cataloging.error.invalid_database");
            this.setMessage(ex);
            return;
        }

        Set<Integer> ids = new TreeSet<Integer>();
        for (int i = 0; i < idList.length; i++) {
            ids.add(Integer.valueOf(idList[i]));
        }

        if (recordDatabase == RecordDatabase.PRIVATE || bo.listContainsPrivateRecord(ids)) {
            AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

            this.authorize(
                    "cataloging.bibliographic",
                    "private_database_access",
                    request.getSchema(),
                    authorizationPoints);
        }

        if (bo.moveRecords(ids, request.getLoggedUserId(), recordDatabase)) {
            this.setMessage(ActionResult.SUCCESS, "cataloging.record.success.move");
        } else {
            this.setMessage(ActionResult.WARNING, "cataloging.record.error.move");
        }
    }

    public void exportRecords(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        String exportId = UUID.randomUUID().toString();
        String idList = request.getString("id_list");
        request.setSessionAttribute(schema, exportId, idList);

        try {
            this.json.put("uuid", exportId);
        } catch (JSONException e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
        }
    }

    // http://localhost:8080/Biblivre5/?controller=download&module=cataloging.export&action=download_export&id={export_id}
    public void downloadExport(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        String exportId = request.getString("id");
        String idList = (String) request.getSessionAttribute(schema, exportId);

        String[] idArray = idList.split(",");
        Set<Integer> ids = new TreeSet<Integer>();
        for (int i = 0; i < idArray.length; i++) {
            ids.add(Integer.valueOf(idArray[i]));
        }

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);

        if (bo.listContainsPrivateRecord(ids)) {
            AuthorizationPoints authorizationPoints = request.getAuthorizationPoints();

            this.authorize(
                    "cataloging.bibliographic",
                    "private_database_access",
                    schema,
                    authorizationPoints);
        }

        final DiskFile exportFile = bo.createExportFile(ids);

        this.setFile(exportFile);

        this.setCallback(exportFile::delete);
    }

    public void autocomplete(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        String query = request.getString("q");
        String datafield = request.getString("datafield", "000");
        String subfield = request.getString("subfield", "a");
        AutocompleteType type =
                request.getEnum(AutocompleteType.class, "type", AutocompleteType.DISABLED);

        if (StringUtils.isBlank(query)) {
            return;
        }

        switch (type) {
            case FIXED_TABLE:
            case FIXED_TABLE_WITH_PREVIOUS_VALUES:
            case PREVIOUS_VALUES:
                {
                    RecordBO bo = RecordBO.getInstance(schema, this.recordType);

                    List<String> list = bo.phraseAutocomplete(datafield, subfield, query);

                    for (String term : list) {
                        this.json.append("data", term);
                    }

                    break;
                }
            case BIBLIO:
            case AUTHORITIES:
            case VOCABULARY:
                DTOCollection<AutocompleteDTO> autocompletion =
                        type.getAutocompletion(schema, query);

                this.json.putOpt("data", autocompletion.toJSONObject());

                break;

            default:
        }
    }

    public void addAttachment(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();

        Integer recordId = request.getInteger("id");

        String uri = request.getString("uri");

        String description = request.getString("description");

        Integer userId = request.getLoggedUserId();

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);

        bo.addAttachment(recordId, uri, description, userId);
    }

    public void removeAttachment(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();

        Integer recordId = request.getInteger("id");
        String uri = request.getString("uri");
        String description = request.getString("description");
        Integer userId = request.getLoggedUserId();

        RecordBO bo = RecordBO.getInstance(schema, this.recordType);
        bo.removeAttachment(recordId, uri, description, userId);
    }

    public void listBriefFormats(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();

        // Record tab
        List<BriefTabFieldFormatDTO> formats = Fields.getBriefFormats(schema, this.recordType);
        DTOCollection<BriefTabFieldFormatDTO> list = new DTOCollection<BriefTabFieldFormatDTO>();
        list.addAll(formats);
        try {
            this.json.put("data", list.toJSONObject());
        } catch (Exception e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
        }
    }

    protected abstract RecordDTO createRecordDTO(ExtendedRequest request);
}
