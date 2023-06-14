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
package biblivre.circulation.user;

import biblivre.core.AbstractDAO;
import biblivre.core.DTOCollection;
import biblivre.core.PagingDTO;
import biblivre.core.PreparedStatementUtil;
import biblivre.core.SchemaThreadLocal;
import biblivre.core.exceptions.DAOException;
import biblivre.core.function.UnsafeFunction;
import biblivre.core.utils.CalendarUtils;
import biblivre.core.utils.TextUtils;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.DateUtils;

public class UserDAOImpl extends AbstractDAO implements UserDAO {

    public static UserDAO getInstance() {
        return AbstractDAO.getInstance(UserDAOImpl.class);
    }

    @Override
    public Map<Integer, UserDTO> map(Set<Integer> ids) {
        Map<Integer, UserDTO> map = new HashMap<>();

        Connection con = null;
        try {
            con = this.getConnection();

            String sql = "SELECT U.id, U.name, U.type, U.photo_id, U.status, U.login_id, U.created, U.created_by, U.modified, U.modified_by, U.user_card_printed, array_agg(V.key) as keys, array_agg(V.value) as values " +
                    "FROM users U LEFT JOIN users_values V on V.user_id = U.id " +
                    "WHERE U.id in (" +
                    StringUtils.repeat("?", ", ", ids.size()) +
                    ") GROUP BY U.id, U.name, U.type, U.photo_id, U.status, U.login_id, U.created, U.created_by, U.modified, U.modified_by, U.user_card_printed;";

            PreparedStatement pst = con.prepareStatement(sql);
            int index = 1;
            for (Integer id : ids) {
                pst.setInt(index++, id);
            }

            ResultSet rs = pst.executeQuery();

            while (rs.next()) {
                UserDTO user = this.populateDTO(rs);
                map.put(user.getId(), user);
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return map;
    }

    @Override
    public DTOCollection<UserDTO> search(UserSearchDTO dto, int limit, int offset) {
        DTOCollection<UserDTO> list = new DTOCollection<>();
        String query = dto.getQuery();

        if (StringUtils.isNotBlank(query)) {
            query = TextUtils.removeDiacriticals(query);
        }

        Connection con = null;
        try {
            con = this.getConnection();

            StringBuilder sql = new StringBuilder();
            sql.append(
                    "SELECT U.id, U.name, U.type, U.photo_id, U.status, U.login_id, U.created, U.created_by, U.modified, U.modified_by, U.user_card_printed, array_agg(V.key) as keys, array_agg(V.value) as values FROM users U ");
            sql.append("LEFT JOIN users_values V on V.user_id = U.id ");

            if (dto.isInactiveOnly()) {
                sql.append("WHERE U.status = '").append(UserStatus.INACTIVE).append("' ");
            } else {
                sql.append("WHERE U.status <> '").append(UserStatus.INACTIVE).append("' ");
            }

            StringBuilder countSql = new StringBuilder();
            countSql.append("SELECT count(*) as total FROM users U ");
            if (dto.isInactiveOnly()) {
                countSql.append("WHERE U.status = '").append(UserStatus.INACTIVE).append("' ");
            } else {
                countSql.append("WHERE U.status <> '").append(UserStatus.INACTIVE).append("' ");
            }

            if (StringUtils.isNotBlank(dto.getField())) {
                sql.append(
                        "AND U.id in (SELECT user_id FROM users_values WHERE key = ? AND ascii ilike ?) ");
                countSql.append(
                        "AND U.id in (SELECT user_id FROM users_values WHERE key = ? AND ascii ilike ?) ");
            } else if (StringUtils.isNotBlank(query)) {
                // If field is blank, user is searching the user id or user name
                if (StringUtils.isNumeric(query)) {
                    sql.append("AND (U.id = ?) ");
                    countSql.append("AND (U.id = ?) ");
                } else {
                    sql.append("AND (U.name_ascii ilike ?) ");
                    countSql.append("AND (U.name_ascii ilike ?) ");
                }
            }

            if (dto.getType() != null && dto.getType() > 0) {
                sql.append("AND U.type = ? ");
                countSql.append("AND U.type = ? ");
            }

            if (dto.isPendingFines()) {
                sql.append(
                        "AND U.id in (SELECT user_id FROM lending_fines WHERE fine_value > 0 AND payment_date is null) ");
                countSql.append(
                        "AND U.id in (SELECT user_id FROM lending_fines WHERE fine_value > 0 AND payment_date is null) ");
            }

            if (dto.isLateLendings()) {
                sql.append(
                        "AND U.id in (SELECT user_id FROM lendings WHERE return_date is null AND expected_return_date < now()) ");
                countSql.append(
                        "AND U.id in (SELECT user_id FROM lendings WHERE return_date is null AND expected_return_date < now()) ");
            }

            if (dto.isLoginAccess()) {
                sql.append("AND U.login_id is not null ");
                countSql.append("AND U.login_id is not null ");
            }

            if (dto.isUserCardNeverPrinted()) {
                sql.append("AND U.user_card_printed = false ");
                countSql.append("AND U.user_card_printed = false ");
            }

            if (dto.getCreatedStartDate() != null) {
                sql.append("AND U.created >= ? ");
                countSql.append("AND U.created >= ? ");
            }

            if (dto.getCreatedEndDate() != null) {
                sql.append("AND U.created < ? ");
                countSql.append("AND U.created < ? ");
            }

            if (dto.getModifiedStartDate() != null) {
                sql.append("AND U.modified >= ? ");
                countSql.append("AND U.modified >= ? ");
            }

            if (dto.getModifiedEndDate() != null) {
                sql.append("AND U.modified < ? ");
                countSql.append("AND U.modified < ? ");
            }

            sql.append(
                    "GROUP BY U.id, U.name, U.type, U.photo_id, U.status, U.login_id, U.created, U.created_by, U.modified, U.modified_by, U.user_card_printed ");
            sql.append("ORDER BY UPPER(U.name) ASC ");
            sql.append("LIMIT ? OFFSET ?;");

            PreparedStatement pst = con.prepareStatement(sql.toString());
            PreparedStatement pstCount = con.prepareStatement(countSql.toString());
            int psIndex = 1;

            if (StringUtils.isNotBlank(dto.getField())) {
                pst.setString(psIndex, dto.getField());
                pstCount.setString(psIndex, dto.getField());
                psIndex++;

                pst.setString(psIndex, "%" + query + "%");
                pstCount.setString(psIndex, "%" + query + "%");
                psIndex++;
            } else if (StringUtils.isNotBlank(query)) {
                if (StringUtils.isNumeric(query)) {
                    pst.setInt(psIndex, Integer.parseInt(query));
                    pstCount.setInt(psIndex, Integer.parseInt(query));
                    psIndex++;
                } else {
                    pst.setString(psIndex, "%" + query + "%");
                    pstCount.setString(psIndex, "%" + query + "%");
                    psIndex++;
                }
            }

            if (dto.getType() != null && dto.getType() > 0) {
                pst.setInt(psIndex, dto.getType());
                pstCount.setInt(psIndex, dto.getType());
                psIndex++;
            }

            if (dto.getCreatedStartDate() != null) {
                pst.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(dto.getCreatedStartDate()));
                pstCount.setTimestamp(
                        psIndex, CalendarUtils.toSqlTimestamp(dto.getCreatedStartDate()));
                psIndex++;
            }

            if (dto.getCreatedEndDate() != null) {
                Date date = dto.getCreatedEndDate();
                if (CalendarUtils.isMidnight(date)) {
                    date = DateUtils.addDays(date, 1);
                }

                pst.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(date));
                pstCount.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(date));
                psIndex++;
            }

            if (dto.getModifiedStartDate() != null) {
                pst.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(dto.getModifiedStartDate()));
                pstCount.setTimestamp(
                        psIndex, CalendarUtils.toSqlTimestamp(dto.getModifiedStartDate()));
                psIndex++;
            }

            if (dto.getModifiedEndDate() != null) {
                Date date = dto.getModifiedStartDate();
                if (CalendarUtils.isMidnight(date)) {
                    date = DateUtils.addDays(date, 1);
                }

                pst.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(date));
                pstCount.setTimestamp(psIndex, CalendarUtils.toSqlTimestamp(date));
                psIndex++;
            }

            pst.setInt(psIndex++, limit);
            pst.setInt(psIndex++, offset);

            ResultSet rs = pst.executeQuery();
            ResultSet rsCount = pstCount.executeQuery();

            while (rs.next()) {
                UserDTO userDTO = this.populateDTO(rs);
                list.add(userDTO);
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

    @Override
    public boolean save(UserDTO user) {
        try (Connection con = this.getConnection()) {
            con.setAutoCommit(false);

            StringBuilder sql = new StringBuilder();
            PreparedStatement pst;
            boolean newUser = user.getId() == 0;

            if (newUser) {
                user.setId(this.getNextSerial("users_id_seq"));
                sql.append(
                        "INSERT INTO users (id, name, type, photo_id, status, created_by, name_ascii) ");
                sql.append("VALUES (?, ?, ?, ?, ?, ?, ?);");
                pst = con.prepareStatement(sql.toString());
                pst.setInt(1, user.getId());
                pst.setString(2, user.getName());
                pst.setInt(3, user.getType());
                pst.setString(4, user.getPhotoId());
                pst.setString(5, user.getStatus().toString());
                pst.setInt(6, user.getCreatedBy());
                pst.setString(7, TextUtils.removeDiacriticals(user.getName()));
            } else {
                sql.append("UPDATE users SET modified = now(), ");
                sql.append(
                        "type = ?, photo_id = ?, status = ?, name = ?, modified_by = ?, user_card_printed = ?, name_ascii = ? ");
                sql.append("WHERE id = ?;");
                pst = con.prepareStatement(sql.toString());
                pst.setInt(1, user.getType());
                pst.setString(2, user.getPhotoId());
                pst.setString(3, user.getStatus().toString());
                pst.setString(4, user.getName());
                pst.setInt(5, user.getCreatedBy());
                pst.setBoolean(6, user.getUserCardPrinted());
                pst.setString(7, TextUtils.removeDiacriticals(user.getName()));
                pst.setInt(8, user.getId());
            }

            pst.executeUpdate();

            Map<String, String> fields = user.getFields();

            for (Entry<String, String> entry : fields.entrySet()) {
                updateUserValue(user, entry.getKey(), entry.getValue(), con::prepareStatement);
            }

            con.commit();

            return true;
        } catch (Exception e) {
            throw new DAOException(e);
        }
    }

    @Override
    public boolean delete(UserDTO user) {
        Connection con = null;
        try {
            con = this.getConnection();
            con.setAutoCommit(false);

            StringBuilder sql;
            PreparedStatement pst;

            sql = new StringBuilder();
            sql.append("DELETE FROM users ");
            sql.append("WHERE id = ? AND status = '" + UserStatus.INACTIVE + "';");
            pst = con.prepareStatement(sql.toString());
            pst.setInt(1, user.getId());

            if (pst.executeUpdate() > 0) {
                // Delete from logins table
                String loginSql = "SELECT login_id FROM users WHERE id = ?;";
                PreparedStatement loginPst = con.prepareStatement(loginSql);

                loginPst.setInt(1, user.getId());
                ResultSet rs = loginPst.executeQuery();
                int loginId = 0;
                if (rs.next()) {
                    loginId = rs.getInt("login_id");
                }
                if (loginId != 0) {
                    loginSql = "DELETE FROM logins WHERE id = ?;";
                    loginPst = con.prepareStatement(loginSql);
                    loginPst.setInt(1, loginId);
                    loginPst.executeUpdate();
                }

            } else {
                sql = new StringBuilder();
                sql.append("UPDATE users SET status = '" + UserStatus.INACTIVE + "' ");
                sql.append("WHERE id = ? ;");
                pst = con.prepareStatement(sql.toString());
                pst.setInt(1, user.getId());
                pst.executeUpdate();
            }

            con.commit();
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
        return true;
    }

    private UserDTO populateDTO(ResultSet rs) throws SQLException {
        UserDTO dto = new UserDTO();

        dto.setId(rs.getInt("id"));
        dto.setName(rs.getString("name"));
        dto.setType(rs.getInt("type"));
        dto.setPhotoId(rs.getString("photo_id"));
        dto.setStatus(rs.getString("status"));
        dto.setLoginId(rs.getInt("login_id"));
        dto.setCreated(rs.getTimestamp("created"));
        dto.setCreatedBy(rs.getInt("created_by"));
        dto.setModified(rs.getTimestamp("modified"));
        dto.setModifiedBy(rs.getInt("modified_by"));
        dto.setUserCardPrinted(rs.getBoolean("user_card_printed"));

        String[] keys = (String[]) rs.getArray("keys").getArray();
        String[] values = (String[]) rs.getArray("values").getArray();

        for (int i = 0; i < keys.length; i++) {
            if (keys[i] != null) {
                dto.addField(keys[i], values[i]);
            }
        }

        return dto;
    }

    @Override
    public void markAsPrinted(Set<Integer> ids) {
        Connection con = null;

        try {
            con = this.getConnection();

            String sql = "UPDATE users SET user_card_printed = true " +
                    "WHERE id in (" +
                    StringUtils.repeat("?", ", ", ids.size()) +
                    ");";

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
    public boolean updateUserStatus(Integer userId, UserStatus status) {
        Connection con = null;

        try {
            con = this.getConnection();

            String sql = "UPDATE users SET status = ? " +
                    "WHERE id = ?;";

            PreparedStatement pst = con.prepareStatement(sql);
            pst.setString(1, status.toString());
            pst.setInt(2, userId);

            pst.executeUpdate();
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }
        return true;
    }

    @Override
    public Integer getUserIdByLoginId(Integer loginId) {

        if (loginId == null) return null;

        Connection con = null;
        try {
            con = this.getConnection();

            PreparedStatement pst = con.prepareStatement("SELECT id FROM users WHERE login_id = ?;");
            pst.setInt(1, loginId);

            ResultSet rs = pst.executeQuery();

            if (rs.next()) {
                return rs.getInt("id");
            }
        } catch (Exception e) {
            throw new DAOException(e);
        } finally {
            this.closeConnection(con);
        }

        return null;
    }

    private void updateUserValue(
            UserDTO user,
            String key,
            String value,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        if (SchemaThreadLocal.isGlobalSchema()) {
            return;
        }

        String currentValue = getCurrentValue(user.getId(), key, preparedStatementGenerator);

        if (value != null && value.equals(currentValue)) {
            return;
        }

        if (currentValue == null) {
            insertValue(
                    user.getId(),
                    key,
                    value,
                    TextUtils.removeDiacriticals(value),
                    preparedStatementGenerator);
        } else {
            updateValue(
                    user.getId(),
                    key,
                    value,
                    TextUtils.removeDiacriticals(value),
                    preparedStatementGenerator);
        }
    }

    private void updateValue(
            int userId,
            String key,
            String value,
            String ascii,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql = "UPDATE users_values SET value = ?, ascii = ? WHERE user_id = ? AND key = ?";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(preparedStatement, value, ascii, userId, key);

            preparedStatement.execute();
        }
    }

    private void insertValue(
            int userId,
            String key,
            String value,
            String ascii,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql = "INSERT INTO users_values (user_id, key, value, ascii) VALUES (?, ?, ?, ?)";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(preparedStatement, userId, key, value, ascii);

            preparedStatement.execute();
        }
    }

    private String getCurrentValue(
            int userId,
            String key,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql = "SELECT value FROM users_values WHERE user_id = ? AND key = ?";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(preparedStatement, userId, key);

            ResultSet resultSet = preparedStatement.executeQuery();

            if (resultSet.next()) {
                return resultSet.getString(1);
            }
        }

        return null;
    }
}
