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
package biblivre.administration.backup;

import java.io.File;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;

import biblivre.core.persistence.AbstractDAO;
import biblivre.core.persistence.sql.NullableSQLObject;

public class BackupDAO extends AbstractDAO implements IBackupDAO {
	private static final String _SAVE_UPDATE_SQL =
		"UPDATE backups " +
		"SET path = ?, downloaded = ?, current_step = ? " +
		"WHERE id = ?";

	private static final String _LIST_SQL =
		"SELECT * FROM backups " +
		"ORDER BY created DESC ";

	private static final String _LIST_WITH_LIMIT_SQL =
		"SELECT * FROM backups " +
		"ORDER BY created DESC LIMIT ?";

	private static final String _LIST_SCHEMAS_SQL =
		"SELECT schema_name FROM information_schema.schemata " +
		"WHERE schema_name <> 'information_schema' " +
			"AND schema_name !~ E'^pg_';";

	private static final String _GET_SQL =
		"SELECT * FROM backups WHERE id = ?";

	private static final String _INSERT_SQL =
		"INSERT INTO backups " +
		"(id, path, schemas, type, scope, downloaded, steps, current_step) " +
		"VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

	@Override
	public boolean save(BackupDTO dto) {
		if (dto == null || dto.getType() == null) {
			return false;
		}

		if (dto.getId() == null) {
			return onTransactionContext(con -> {
				Integer id = getNextSerial(con, "backups_id_seq");

				dto.setId(id);

				return executeUpdate(
					_INSERT_SQL, id,
					_getNullableAbsolutPath(dto),
					dto.getSchemasString(), dto.getType().toString(),
					dto.getBackupScope().toString(), dto.isDownloaded(),
					dto.getSteps(), dto.getCurrentStep());
			});
		}
		else {
			return executeUpdate(
				_SAVE_UPDATE_SQL, _getNullableAbsolutPath(dto),
				dto.isDownloaded(), dto.getCurrentStep(), dto.getId());
		}
	}

	@Override
	public BackupDTO get(Integer id) {
		if (id == null) {
			return null;
		}

		return fetchOne(
			this::populateDTO, _GET_SQL, id);
	}

	@Override
	public Set<String> listDatabaseSchemas() {
		List<String> list =
			listWith(rs -> rs.getString("schema_name"), _LIST_SCHEMAS_SQL);

		return new HashSet<>(list);
	}

	@Override
	public List<BackupDTO> list() {
		return this.list(0);
	}

	@Override
	public List<BackupDTO> list(int limit) {
		List<Object> parameters;

		String sql;

		if (limit > 0) {
			sql = _LIST_WITH_LIMIT_SQL;

			parameters = Collections.singletonList(limit);
		}
		else {
			sql = _LIST_SQL;

			parameters = Collections.emptyList();
		}

		return listWith(this::populateDTO, sql, parameters.toArray());
	}

	private Object _getNullableAbsolutPath(BackupDTO dto) {
		if (dto.getBackup() != null) {
			return dto.getBackup().getAbsolutePath();
		}
		else {
			return NullableSQLObject.VARCHAR;
		}
	}

	private BackupDTO populateDTO(ResultSet rs) throws SQLException {
		String schemas = rs.getString("schemas");
		BackupType type = BackupType.fromString(rs.getString("type"));
		BackupScope scope = BackupScope.fromString(rs.getString("scope"));

		BackupDTO dto = new BackupDTO(schemas, type, scope);

		dto.setId(rs.getInt("id"));
		dto.setCreated(rs.getTimestamp("created"));

		String path = rs.getString("path");
		if (StringUtils.isNotBlank(path)) {
			dto.setBackup(new File(path));
		}

		dto.setDownloaded(rs.getBoolean("downloaded"));
		dto.setSteps(rs.getInt("steps"));
		dto.setCurrentStep(rs.getInt("current_step"));

		return dto;
	}
}
