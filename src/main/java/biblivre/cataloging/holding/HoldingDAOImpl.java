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
package biblivre.cataloging.holding;

import biblivre.cataloging.RecordDAOImpl;
import biblivre.cataloging.RecordDTO;
import biblivre.cataloging.bibliographic.BiblioRecordDTO;
import biblivre.cataloging.enums.HoldingAvailability;
import biblivre.cataloging.enums.RecordDatabase;
import biblivre.cataloging.search.SearchDTO;
import biblivre.cataloging.search.SearchTermDTO;
import biblivre.circulation.user.UserDTO;
import biblivre.core.AbstractDAO;
import biblivre.core.DTOCollection;
import biblivre.core.PagingDTO;
import biblivre.core.enums.SearchMode;
import biblivre.core.exceptions.DAOException;
import biblivre.core.utils.CalendarUtils;
import biblivre.core.utils.CharPool;
import biblivre.core.utils.StringPool;
import biblivre.login.LoginDTO;
import biblivre.marc.MarcDataReader;
import biblivre.marc.MarcUtils;
import biblivre.marc.MaterialType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.DateUtils;
import org.marc4j.marc.Record;

public class HoldingDAOImpl extends RecordDAOImpl implements HoldingDAO {

    private static final int ADMIN_OR_REMOVED_LOGIN_ID = 0;

    public static HoldingDAOImpl getInstance() {
        return AbstractDAO.getInstance(HoldingDAOImpl.class);
    }

    @Override
    public Integer count(int recordId, boolean availableOnly) {
        Connection con = null;

        try {
            con = this.getConnection();

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT count(*) as total FROM biblio_holdings WHERE 1 = 1 ");

            if (recordId != 0) {
                sql.append("and record_id  = ? ");
            }

            if (availableOnly) {
                sql.append("and availability = '")
                        .append(HoldingAvailability.AVAILABLE)
                        .append(CharPool.QUOTE);
            }

            PreparedStatement pst = con.prepareStatement(sql.toString());

            int index = 1;
            if (recordId != 0) {
                pst.setInt(index++, recordId);
            }

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                return rs.getInt("total");
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return 0;
    }

    @Override
    public HoldingDTO getByAccessionNumber(String accessionNumber) {
        HoldingDTO dto = null;
        Connection con = null;
        try {
            con = this.getConnection();
            String sql = "SELECT * FROM biblio_holdings WHERE accession_number = ?;";

            PreparedStatement pst = con.prepareStatement(sql);
            pst.setString(1, accessionNumber);

            ResultSet rs = pst.executeQuery();
            while (rs.next()) {
                dto = (HoldingDTO) this.populateDTO(rs);
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return dto;
    }

    @Override
    public Map<Integer, RecordDTO> map(Set<Integer> ids) {
        Map<Integer, RecordDTO> map = new HashMap<>();

        Connection con = null;
        try {
            con = this.getConnection();
            String sql =
                    "SELECT * FROM biblio_holdings "
                            + "WHERE id in ("
                            + StringUtils.repeat("?", ", ", ids.size())
                            + ");";

            PreparedStatement pst = con.prepareStatement(sql);
            int index = 1;
            for (Integer id : ids) {
                pst.setInt(index++, id);
            }

            ResultSet rs = pst.executeQuery();
            while (rs.next()) {
                RecordDTO dto = this.populateDTO(rs);
                map.put(dto.getId(), dto);
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return map;
    }

    @Override
    public List<RecordDTO> list(int offset, int limit) {
        List<RecordDTO> list = new ArrayList<>();

        Connection con = null;
        try {
            con = this.getConnection();
            String sql = "SELECT * biblio_holdings ORDER BY id OFFSET ? LIMIT ?;";

            PreparedStatement pst = con.prepareStatement(sql);

            pst.setInt(1, offset);
            pst.setInt(2, limit);

            ResultSet rs = pst.executeQuery();

            while (rs.next()) {
                try {
                    list.add(this.populateDTO(rs));
                } catch (Exception e) {
                    this.logger.error(e.getMessage(), e);
                }
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return list;
    }

    @Override
    public boolean save(RecordDTO dto) {
        Connection con = null;
        HoldingDTO holding = (HoldingDTO) dto;

        try {
            con = this.getConnection();
            int id = this.getNextSerial("biblio_holdings_id_seq");
            holding.setId(id);
            String sql =
                    "INSERT INTO biblio_holdings "
                            + "(id, record_id, iso2709, availability, database, material, accession_number, location_d, created_by) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?); ";

            PreparedStatement pst = con.prepareStatement(sql);
            pst.setInt(1, holding.getId());
            pst.setInt(2, holding.getRecordId());
            pst.setString(3, holding.getUTF8Iso2709());
            pst.setString(4, holding.getAvailability().toString());
            pst.setString(5, holding.getRecordDatabase().toString());
            pst.setString(6, holding.getMaterialType().toString());
            pst.setString(7, holding.getAccessionNumber());
            pst.setString(8, holding.getLocationD());
            pst.setInt(9, holding.getCreatedBy());

            return pst.executeUpdate() > 0;
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public void updateHoldingCreationCounter(UserDTO dto, LoginDTO ldto) {
        Connection con = null;
        try {
            con = this.getConnection();

            String sql =
                    "INSERT INTO holding_creation_counter "
                            + "(user_name, user_login, created_by) "
                            + "VALUES (?, ?, ?); ";

            PreparedStatement pst = con.prepareStatement(sql);

            pst.setString(1, dto == null ? StringPool.BLANK : dto.getName());

            if (ldto != null) {
                pst.setString(2, ldto.getLogin());
                pst.setInt(3, ADMIN_OR_REMOVED_LOGIN_ID);
            } else {
                pst.setNull(2, java.sql.Types.VARCHAR);
                pst.setNull(3, java.sql.Types.INTEGER);
            }

            pst.executeUpdate();
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public boolean update(RecordDTO dto) {
        Connection con = null;
        HoldingDTO holding = (HoldingDTO) dto;

        try {
            con = this.getConnection();

            String sql =
                    "UPDATE biblio_holdings "
                            + "SET record_id = ?, iso2709 = ?, availability = ?, accession_number = ?, location_d = ?, label_printed = ?, modified = now(), modified_by = ? "
                            + "WHERE id = ?;";

            PreparedStatement pst = con.prepareStatement(sql);
            pst.setInt(1, holding.getRecordId());
            pst.setString(2, holding.getUTF8Iso2709());
            pst.setString(3, holding.getAvailability().toString());
            pst.setString(4, holding.getAccessionNumber());
            pst.setString(5, holding.getLocationD());
            pst.setBoolean(6, holding.getLabelPrinted());
            pst.setInt(7, holding.getModifiedBy());
            pst.setInt(8, holding.getId());

            return pst.executeUpdate() > 0;
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public void markAsPrinted(Set<Integer> ids) {
        Connection con = null;

        try {
            con = this.getConnection();

            String sql =
                    "UPDATE biblio_holdings SET label_printed = true "
                            + "WHERE id in ("
                            + StringUtils.repeat("?", ", ", ids.size())
                            + ");";

            PreparedStatement pst = con.prepareStatement(sql);
            int index = 1;
            for (Integer id : ids) {
                pst.setInt(index++, id);
            }

            pst.executeUpdate();
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public boolean delete(RecordDTO dto) {
        Connection con = null;

        try {
            con = this.getConnection();

            PreparedStatement pst =
                    con.prepareStatement("DELETE FROM biblio_holdings WHERE id = ?;");
            pst.setInt(1, dto.getId());

            return pst.executeUpdate() > 0;

        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public final int getNextAccessionNumber(String accessionPrefix) {
        Connection con = null;

        try {
            con = this.getConnection();
            String sql =
                    "SELECT max(COALESCE(CAST(SUBSTRING(accession_number FROM '([0-9]{1,10})$') AS INTEGER), 0)) as accession "
                            + "FROM biblio_holdings WHERE accession_number > ? and accession_number < ?;";

            PreparedStatement pst = con.prepareStatement(sql);
            pst.setString(1, accessionPrefix + "0");
            pst.setString(2, accessionPrefix + "99999999999999999999");

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                return rs.getInt("accession") + 1;
            }

        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return 0;
    }

    @Override
    public boolean isAccessionNumberAvailable(String accessionNumber, int holdingId) {
        Connection con = null;
        try {
            con = this.getConnection();

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT count(*) FROM biblio_holdings WHERE accession_number = ? ");

            if (holdingId != 0) {
                sql.append("AND id <> ?;");
            }

            PreparedStatement pst = con.prepareStatement(sql.toString());
            pst.setString(1, accessionNumber);

            if (holdingId != 0) {
                pst.setInt(2, holdingId);
            }

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                return rs.getInt(1) == 0;
            }

        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return false;
    }

    @Override
    public DTOCollection<HoldingDTO> list(int recordId) {
        DTOCollection<HoldingDTO> list = new DTOCollection<>();

        Connection con = null;
        try {
            con = this.getConnection();

            PreparedStatement pst =
                    con.prepareStatement("SELECT * FROM biblio_holdings WHERE record_id = ?;");
            pst.setInt(1, recordId);

            ResultSet rs = pst.executeQuery();
            while (rs.next()) {
                list.add((HoldingDTO) this.populateDTO(rs));
            }

        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return list;
    }

    @Override
    public DTOCollection<HoldingDTO> search(
            String query, RecordDatabase database, boolean lentOnly, int offset, int limit) {
        DTOCollection<HoldingDTO> list = new DTOCollection<>();
        Connection con = null;
        try {
            boolean searchId = StringUtils.isNumeric(query);
            try {
                Long.valueOf(query);
            } catch (NumberFormatException nfe) {
                searchId = false;
            }
            boolean listAll = StringUtils.isBlank(query);

            con = this.getConnection();
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT * FROM biblio_holdings WHERE 1 = 1 ");

            if (database != null) {
                sql.append("AND database = ? ");
            }

            if (!listAll) {
                if (searchId) {
                    sql.append("AND (accession_number ilike ? OR id = ?) ");
                } else {
                    sql.append("AND accession_number ilike ? ");
                }
            }

            if (lentOnly) {
                sql.append(
                        " AND id in (SELECT holding_id FROM lendings WHERE return_date is null) ");
            }

            sql.append("LIMIT ? OFFSET ? ");

            StringBuilder countSql = new StringBuilder();
            countSql.append("SELECT count(*) as total FROM biblio_holdings WHERE 1 = 1 ");

            if (database != null) {
                countSql.append("AND database = ? ");
            }

            if (!listAll) {
                if (searchId) {
                    countSql.append("AND (accession_number ilike ? OR id = ?) ");
                } else {
                    countSql.append("AND accession_number ilike ? ");
                }
            }

            if (lentOnly) {
                countSql.append(
                        " AND id in (SELECT holding_id FROM lendings WHERE return_date is null) ");
            }

            PreparedStatement pst = con.prepareStatement(sql.toString());
            PreparedStatement pstCount = con.prepareStatement(countSql.toString());

            int index = 1;

            if (database != null) {
                pst.setString(index, database.toString());
                pstCount.setString(index++, database.toString());
            }

            if (!listAll) {
                pst.setString(index, query);
                pstCount.setString(index++, query);

                if (searchId) {
                    pst.setLong(index, Long.parseLong(query));
                    pstCount.setLong(index++, Long.parseLong(query));
                }
            }

            pst.setInt(index++, limit);
            pst.setInt(index++, offset);

            ResultSet rs = pst.executeQuery();
            ResultSet rsCount = pstCount.executeQuery();

            while (rs.next()) {
                list.add((HoldingDTO) this.populateDTO(rs));
            }

            if (rsCount.next()) {
                int total = rsCount.getInt("total");

                PagingDTO paging = new PagingDTO(total, limit, offset);
                list.setPaging(paging);
            }

        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
        return list;
    }

    private String createAdvancedWhereClause(SearchDTO search) {
        if (search == null) {
            return "";
        }

        SearchTermDTO created = null;
        SearchTermDTO modified = null;
        SearchTermDTO printed = null;

        for (SearchTermDTO dto : search.getQuery().getTerms()) {
            if (dto.getField().equals("holding_created")) {
                created = dto;
            } else if (dto.getField().equals("holding_modified")) {
                modified = dto;
            } else if (dto.getField().equals("holding_label_never_printed")) {
                printed = dto;
            }
        }

        StringBuilder sql = new StringBuilder();

        if (created != null) {
            sql.append("AND (");

            if (created.getStartDate() != null) {
                sql.append("H.created >= ? ");
            }

            if ((created.getStartDate() != null) && (created.getEndDate() != null)) {
                sql.append("AND ");
            }

            if (created.getEndDate() != null) {
                sql.append("H.created < ? ");
            }

            sql.append(") ");
        }

        if (modified != null) {
            sql.append("AND (");

            if (modified.getStartDate() != null) {
                sql.append("H.modified >= ? ");
            }

            if ((modified.getStartDate() != null) && (modified.getEndDate() != null)) {
                sql.append("AND ");
            }

            if (modified.getEndDate() != null) {
                sql.append("H.modified < ? ");
            }

            sql.append(") ");
        }

        if (printed != null) {
            sql.append("AND H.label_printed = false ");
        }

        return sql.toString();
    }

    private int populatePreparedStatement(PreparedStatement pst, int index, SearchDTO search)
            throws SQLException {
        if (search == null) {
            return index;
        }

        SearchTermDTO created = null;
        SearchTermDTO modified = null;

        for (SearchTermDTO dto : search.getQuery().getTerms()) {
            if (dto.getField().equals("holding_created")) {
                created = dto;
            } else if (dto.getField().equals("holding_modified")) {
                modified = dto;
            }
        }

        if (created != null) {
            Date startDate = created.getStartDate();
            Date endDate = created.getEndDate();

            if (startDate != null) {
                pst.setTimestamp(index++, CalendarUtils.toSqlTimestamp(startDate));
            }

            if (endDate != null) {
                if (CalendarUtils.isMidnight(endDate)) {
                    endDate = DateUtils.addDays(endDate, 1);
                }

                pst.setTimestamp(index++, CalendarUtils.toSqlTimestamp(endDate));
            }
        }

        if (modified != null) {

            Date startDate = modified.getStartDate();
            Date endDate = modified.getEndDate();

            if (startDate != null) {
                pst.setTimestamp(index++, CalendarUtils.toSqlTimestamp(startDate));
            }

            if (endDate != null) {
                if (CalendarUtils.isMidnight(endDate)) {
                    endDate = DateUtils.addDays(endDate, 1);
                }

                pst.setTimestamp(index++, CalendarUtils.toSqlTimestamp(endDate));
            }
        }

        return index;
    }

    @Override
    public Integer count(SearchDTO search) {
        Connection con = null;

        boolean useDatabase = false;
        boolean useMaterialType = false;

        if (search != null && search.getQuery() != null) {
            useDatabase = search.getQuery().getDatabase() != null;
            useMaterialType = search.getQuery().getMaterialType() != MaterialType.ALL;
        }

        try {
            con = this.getConnection();

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT count(H.id) as total FROM biblio_holdings H ");
            sql.append("INNER JOIN biblio_records B ON H.record_id = B.id WHERE 1 = 1 ");

            sql.append(this.createAdvancedWhereClause(search));

            if (useDatabase) {
                sql.append("AND B.database = ? ");
            }

            if (useMaterialType) {
                sql.append("AND B.material = ? ");
            }

            PreparedStatement pst = con.prepareStatement(sql.toString());

            int index = 1;

            index = this.populatePreparedStatement(pst, index, search);

            if (useDatabase && search != null) {
                pst.setString(index++, search.getQuery().getDatabase().toString());
            }

            if (useMaterialType && search != null) {
                pst.setString(index++, search.getQuery().getMaterialType().toString());
            }

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                return rs.getInt("total");
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return 0;
    }

    @Override
    public Map<Integer, Integer> countSearchResults(SearchDTO search) {
        Map<Integer, Integer> count = new HashMap<>();
        if (search == null) {
            return count;
        }

        if (search.getSearchMode() == SearchMode.LIST_ALL) {
            count.put(0, this.count(search));
            return count;
        }

        Connection con = null;
        try {
            con = this.getConnection();

            String sql =
                    "SELECT 0 as indexing_group_id, COUNT(DISTINCT H.id) as total FROM biblio_holdings H "
                            + "INNER JOIN biblio_search_results B ON H.record_id = B.record_id "
                            + "WHERE B.search_id = ? "
                            + this.createAdvancedWhereClause(search)
                            + "UNION "
                            + "SELECT B.indexing_group_id, COUNT(DISTINCT H.id) as total FROM biblio_holdings H "
                            + "INNER JOIN biblio_search_results B ON H.record_id = B.record_id "
                            + "WHERE B.search_id = ? "
                            + this.createAdvancedWhereClause(search)
                            + "and B.indexing_group_id <> 0 GROUP BY B.indexing_group_id";

            PreparedStatement pst = con.prepareStatement(sql);

            int index = 1;
            pst.setInt(index++, search.getId());
            index = this.populatePreparedStatement(pst, index, search);
            pst.setInt(index++, search.getId());
            index = this.populatePreparedStatement(pst, index, search);

            ResultSet rs = pst.executeQuery();

            while (rs.next()) {
                count.put(rs.getInt("indexing_group_id"), rs.getInt("total"));
            }

            return count;
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    @Override
    public List<RecordDTO> getSearchResults(SearchDTO search) {
        List<RecordDTO> list = new ArrayList<>();

        if (search == null) {
            return list;
        }

        PagingDTO paging = search.getPaging();

        if (paging == null) {
            return list;
        }

        boolean useSearchResult = (search.getSearchMode() != SearchMode.LIST_ALL);
        boolean useIndexingGroup = (search.getIndexingGroup() != 0);
        boolean useMaterialType = (search.getQuery().getMaterialType() != MaterialType.ALL);
        boolean useLimit = (paging.getRecordLimit() > 0);

        Connection con = null;
        try {
            con = this.getConnection();
            StringBuilder sql = new StringBuilder();

            sql.append(
                    "SELECT H.*, R.iso2709 as biblio, trim(substr(S.phrase, ignore_chars_count + 1)) as sort FROM ");

            if (useSearchResult) {
                sql.append("biblio_holdings H INNER JOIN biblio_records R ON H.record_id = R.id ");
                sql.append("INNER JOIN ( ");
                sql.append("SELECT DISTINCT record_id FROM biblio_search_results ");
                sql.append("WHERE search_id = ? ");

                if (useIndexingGroup) {
                    sql.append("AND indexing_group_id = ? ");
                }

                sql.append("ORDER BY record_id DESC ");

                if (useLimit) {
                    sql.append("LIMIT ? ");
                }

                sql.append(") SR ON SR.record_id = R.id ");

                sql.append(this.createAdvancedWhereClause(search));

            } else {
                sql.append("biblio_holdings H INNER JOIN (");
                sql.append("SELECT * FROM biblio_records ");
                sql.append("WHERE database = ? ");

                if (useMaterialType) {
                    sql.append("AND material = ? ");
                }

                sql.append("ORDER BY id DESC ");

                if (useLimit) {
                    sql.append("LIMIT ? ");
                }

                sql.append(") R ON H.record_id = R.id ");
            }

            sql.append("LEFT JOIN biblio_idx_sort S ");
            sql.append("ON S.record_id = R.id AND S.indexing_group_id = ? ");

            sql.append("ORDER BY sort NULLS LAST, R.id ASC OFFSET ? LIMIT ?;");

            int index = 1;

            PreparedStatement pst = con.prepareStatement(sql.toString());

            if (useSearchResult) {
                pst.setInt(index++, search.getId());

                if (useIndexingGroup) {
                    pst.setInt(index++, search.getIndexingGroup());
                }

            } else {
                pst.setString(index++, search.getQuery().getDatabase().toString());

                if (useMaterialType) {
                    pst.setString(index++, search.getQuery().getMaterialType().toString());
                }
            }

            if (useLimit) {
                pst.setInt(index++, search.getRecordLimit());
            }

            index = this.populatePreparedStatement(pst, index, search);

            pst.setInt(index++, search.getSort());

            pst.setInt(index++, paging.getRecordOffset());
            pst.setInt(index++, paging.getRecordsPerPage());

            ResultSet rs = pst.executeQuery();

            while (rs.next()) {
                list.add(this.populateDTO(rs));
            }

            return list;
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
    }

    protected RecordDTO populateDTO(ResultSet rs) throws SQLException {
        HoldingDTO dto = new HoldingDTO();

        dto.setIso2709(rs.getBytes("iso2709"));

        if (this.hasBiblioColumn(rs)) {
            BiblioRecordDTO biblioRecordDTO = new BiblioRecordDTO();

            biblioRecordDTO.setIso2709(rs.getBytes("biblio"));
            biblioRecordDTO.setId(rs.getInt("record_id"));

            Record record = biblioRecordDTO.getRecord();

            if (record == null && biblioRecordDTO.getIso2709() != null) {
                record = MarcUtils.iso2709ToRecord(biblioRecordDTO.getIso2709());
            }

            if (record != null) {
                MarcDataReader marcDataReader = new MarcDataReader(record);

                biblioRecordDTO.setAuthor(marcDataReader.getAuthor(true));
                biblioRecordDTO.setTitle(marcDataReader.getTitle(false));
                biblioRecordDTO.setIsbn(marcDataReader.getIsbn());
                biblioRecordDTO.setIssn(marcDataReader.getIssn());
                biblioRecordDTO.setIsrc(marcDataReader.getIsrc());
                biblioRecordDTO.setPublicationYear(marcDataReader.getPublicationYear());
                biblioRecordDTO.setShelfLocation(marcDataReader.getShelfLocation());
                biblioRecordDTO.setSubject(marcDataReader.getSubject(true));
            }

            dto.setBiblioRecord(biblioRecordDTO);
        }

        dto.setCreated(rs.getTimestamp("created"));
        dto.setCreatedBy(rs.getInt("created_by"));
        dto.setModified(rs.getTimestamp("modified"));
        dto.setModifiedBy(rs.getInt("modified_by"));

        dto.setRecordId(rs.getInt("record_id"));
        dto.setRecordDatabase(rs.getString("database"));
        dto.setMaterialType(rs.getString("material"));
        dto.setAvailability(rs.getString("availability"));

        dto.setAccessionNumber(rs.getString("accession_number"));
        dto.setLocationD(rs.getString("location_d"));
        dto.setLabelPrinted(rs.getBoolean("label_printed"));

        return dto;
    }
}
