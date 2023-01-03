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
package biblivre.core.translations;

import biblivre.core.AbstractDAO;
import biblivre.core.PreparedStatementUtil;
import biblivre.core.SchemaThreadLocal;
import biblivre.core.exceptions.DAOException;
import biblivre.core.function.UnsafeFunction;
import biblivre.core.utils.StringPool;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import org.apache.commons.lang3.StringUtils;

public class TranslationsDAOImpl extends AbstractDAO implements TranslationsDAO {

    public static TranslationsDAOImpl getInstance() {
        return (TranslationsDAOImpl) AbstractDAO.getInstance(TranslationsDAOImpl.class);
    }

    @Override
    public List<TranslationDTO> list() {
        return this.list(null);
    }

    @Override
    public List<TranslationDTO> list(String language) {
        List<TranslationDTO> list = new ArrayList<>();

        Connection con = null;
        try {
            con = this.getConnection();

            String sql =
                    """
                    SELECT K.language, K.key, coalesce(T.text, '') as text, T.created, T.created_by, T.modified, T.modified_by, T.user_created
                    FROM (
                        SELECT DISTINCT B.language, A.key
                        FROM (
                            SELECT DISTINCT key
                            FROM translations
                                UNION SELECT DISTINCT key FROM global.translations
                        ) A
                        CROSS JOIN (
                            SELECT DISTINCT language
                                FROM translations
                                    UNION SELECT DISTINCT language FROM global.translations
                        ) B
                    ) K
                    LEFT JOIN translations T ON T.key = K.key AND T.language = K.language
                    %s
                    ORDER BY K.language, K.key
                    """
                            .formatted(
                                    StringUtils.isNotBlank(language)
                                            ? "WHERE K.language = ? "
                                            : StringPool.BLANK);

            PreparedStatement pst = con.prepareStatement(sql.toString());

            if (StringUtils.isNotBlank(language)) {
                pst.setString(1, language);
            }

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
    public boolean save(Map<String, Map<String, String>> translations, int loggedUser) {
        return this.save(translations, null, loggedUser);
    }

    @Override
    public boolean save(
            Map<String, Map<String, String>> translationsToAdd,
            Map<String, Map<String, String>> translationsToRemove,
            int loggedUser) {
        try (Connection con = getConnection()) {
            con.setAutoCommit(false);

            if (translationsToAdd != null) {
                for (Entry<String, Map<String, String>> entry : translationsToAdd.entrySet()) {
                    String language = entry.getKey();

                    Map<String, String> translation = entry.getValue();

                    for (Entry<String, String> translationEntry : translation.entrySet()) {
                        updateTranslation(
                                language,
                                translationEntry.getKey(),
                                translationEntry.getValue(),
                                loggedUser,
                                con::prepareStatement);
                    }
                }
            }

            if (translationsToRemove != null) {
                String sql = "DELETE FROM translations WHERE language = ? AND key = ?; ";
                PreparedStatement pst = con.prepareStatement(sql);

                for (Entry<String, Map<String, String>> entry : translationsToRemove.entrySet()) {
                    String language = entry.getKey();

                    Map<String, String> translation = entry.getValue();

                    for (String key : translation.keySet()) {
                        pst.setString(1, language);
                        pst.setString(2, key);
                        pst.addBatch();
                    }
                }

                pst.executeBatch();
            }

            this.commit(con);
            return true;
        } catch (Exception e) {
            throw new DAOException(e);
        }
    }

    private void updateTranslation(
            String language,
            String key,
            String value,
            int loggedUser,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String globalValue = getGlobalValue(language, key, preparedStatementGenerator);

        if (value != null && value.equals(globalValue)) {
            deleteFrom(language, key, preparedStatementGenerator);

            return;
        }

        String currentValue = getValue(language, key, preparedStatementGenerator);

        if (value != null && value.equals(currentValue)) {
            return;
        }

        boolean userCreated = globalValue == null && !SchemaThreadLocal.isGlobalSchema();

        if (currentValue == null) {
            insertTranslation(
                    language, key, value, loggedUser, userCreated, preparedStatementGenerator);
        } else {
            updateTranslation(
                    language, key, value, loggedUser, userCreated, preparedStatementGenerator);
        }
    }

    private void updateTranslation(
            String language,
            String key,
            String value,
            int loggedUser,
            boolean userCreated,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql =
                "UPDATE translations SET text = ?, modified = now(), modified_by = ?, WHERE language = ? and key = ?";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(
                    preparedStatement, value, loggedUser, language, key);

            preparedStatement.execute();
        }
    }

    private void insertTranslation(
            String language,
            String key,
            String value,
            int loggedUser,
            boolean userCreated,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql =
                "INSERT INTO translations (language, key, text, created_by, modified_by, user_created) VALUES (?, ?, ?, ?, ?, ?)";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(
                    preparedStatement, language, key, value, loggedUser, loggedUser, userCreated);

            preparedStatement.execute();
        }
    }

    private String getGlobalValue(
            String language,
            String key,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        return getValue(language, key, true, preparedStatementGenerator);
    }

    private String getValue(
            String language,
            String key,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        return getValue(language, key, false, preparedStatementGenerator);
    }

    private void deleteFrom(
            String language,
            String key,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql = "DELETE FROM translations WHERE language = ? AND key = ?";

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(preparedStatement, language, key);

            preparedStatement.execute();
        }
    }

    private String getValue(
            String language,
            String key,
            boolean isGlobal,
            UnsafeFunction<String, PreparedStatement> preparedStatementGenerator)
            throws Exception {
        String sql =
                "SELECT text FROM %stranslations WHERE language = ? AND key = ?"
                        .formatted(isGlobal ? "global." : StringPool.BLANK);

        try (PreparedStatement preparedStatement = preparedStatementGenerator.apply(sql)) {

            PreparedStatementUtil.setAllParameters(preparedStatement, language, key);

            ResultSet resultSet = preparedStatement.executeQuery();

            if (resultSet.next()) {
                return resultSet.getString(1);
            }
        }

        return null;
    }

    private TranslationDTO populateDTO(ResultSet rs) throws SQLException {
        TranslationDTO dto = new TranslationDTO();

        dto.setLanguage(rs.getString("language"));
        dto.setKey(rs.getString("key"));
        dto.setText(rs.getString("text"));

        dto.setCreated(rs.getTimestamp("created"));
        dto.setCreatedBy(rs.getInt("created_by"));
        dto.setModified(rs.getTimestamp("modified"));
        dto.setModifiedBy(rs.getInt("modified_by"));

        dto.setUserCreated(rs.getBoolean("user_created"));

        return dto;
    }
}
