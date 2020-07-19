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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.nio.file.Files;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.apache.commons.compress.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress.archivers.zip.ZipFile;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import biblivre.administration.backup.exception.RestoreException;
import biblivre.administration.setup.State;
import biblivre.core.AbstractBO;
import biblivre.core.exceptions.ValidationException;
import biblivre.core.utils.Constants;
import biblivre.core.utils.DatabaseUtils;
import biblivre.core.utils.FileIOUtils;
import biblivre.core.utils.StringPool;
import biblivre.digitalmedia.DigitalMediaDAO;

public class RestoreBO extends AbstractBO {
	private static final String _UPDATE_DIGITALMEDIA_BLOB_TPL = "UPDATE digital_media SET blob = '%d' WHERE blob = '%d';";
	private static final Pattern _FILE = Pattern.compile("^(\\d+)_(.*)$");
	private static final String _UPDATE_DIGITALMEDIA_TPL = "UPDATE digital_media SET blob = '%d' WHERE id = '%s';";
	private static final String _DROP_RESTORE_DATABASE = "DROP DATABASE IF EXISTS biblivre4_b3b_restore;";
	private static final String _CREATE_RESTORE_DATABASE = "CREATE DATABASE biblivre4_b3b_restore WITH OWNER = biblivre "
		+ "ENCODING = 'UTF8';";
	private static final String _TERMINATE_BACKEND = "SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'biblivre4_b3b_restore' AND procpid <> pg_backend_pid();";
	private static final String _TERMINATE_BACKEND_92 = "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'biblivre4_b3b_restore' AND pid <> pg_backend_pid();";
	private static final String _ALTER_SCHEMA_TPL = "ALTER SCHEMA \"%s\" RENAME TO \"%s\";";
	private static final String _DELETE_SCHEMA_TPL = "DELETE FROM \"%s\".schemas WHERE \"schema\" = '%s';";
	private static final String _INSERT_SCHEMA_TPL = "INSERT INTO \"global\".schemas (schema, name) VALUES ('%s', E'%s');";
	private static final String _DELETE_FROM_SCHEMAS = "DELETE FROM \"global\".schemas WHERE \"schema\" not in (SELECT schema_name FROM information_schema.schemata);";
	private static final Pattern _LO_OPEN = Pattern.compile("(.*lo_open\\(')(.*?)(',.*)");
	private static final Pattern _LO_CREATE = Pattern.compile("lo_create\\('(.*?)'\\)");

	private BackupDAO dao;
	private DigitalMediaDAO digitalMediaDAO;

	private static final String[] _BACKUP_EXTENSIONS =
		new String[]{"b4bz", "b5bz"};

	private static final Logger logger =
		LoggerFactory.getLogger(RestoreBO.class);

	public static RestoreBO getInstance(String schema) {
		RestoreBO bo = AbstractBO.getInstance(RestoreBO.class, schema);

		if (bo.dao == null) {
			bo.dao = BackupDAO.getInstance(schema);
		}

		if (bo.digitalMediaDAO == null) {
			bo.digitalMediaDAO = DigitalMediaDAO.getInstance(schema);
		}

		return bo;
	}

	public List<RestoreDTO> list() {
		BackupBO backupBO = BackupBO.getInstance(this.getSchema());

		File path = backupBO.getBackupDestination();

		if (path == null) {
			path = FileUtils.getTempDirectory();
		}

		if (path == null) {
			throw new ValidationException(
				"administration.maintenance.backup.error.invalid_restore_path");
		}

		List<RestoreDTO> list =
			FileUtils.listFiles(path, _BACKUP_EXTENSIONS, false).stream()
				.map(this::getRestoreDTO)
				.filter(RestoreDTO::isValid)
				.collect(Collectors.toList());

		_sortRestores(list);

		return list;
	}

	public boolean restore(RestoreDTO dto, RestoreDTO partial)
		throws IOException {

		if (!_verifyDTO(dto)) {
			throw new ValidationException(
				"administration.maintenance.backup.error."
					+ "corrupted_backup_file");
		}

		File tmpDir = FileIOUtils.unzip(dto.getBackup());

		String extension = _getExtension(dto);

		if (partial != null) {
			_movePartialFiles(partial, tmpDir);
		}

		_countRestoreSteps(dto, tmpDir, extension);

		boolean restoreBackup = this.restoreBackup(dto, tmpDir);

		FileUtils.deleteQuietly(tmpDir);

		return restoreBackup;
	}

	public boolean restoreBiblivre3(File gzipFile) throws IOException {
		_validateFile(gzipFile);

		File sql = FileIOUtils.ungzipBackup(gzipFile);

		boolean success = (this.recreateBiblivre3RestoreDatabase(false) ||
			this.recreateBiblivre3RestoreDatabase(true));

		if (!success) {
			return false;
		}

		return restoreBackupBiblivre3(sql);
	}

	public synchronized boolean restoreBackup(RestoreDTO dto, File path) {
		Map<String, String> restoreSchemas = dto.getRestoreSchemas();

		_validateRestoreSchemas(restoreSchemas);

		long currentTimestamp = new Date().getTime();

		Set<String> databaseSchemas = dao.listDatabaseSchemas();

		Map<String, String> deleteSchemas = new HashMap<>();
		Map<String, String> preRenameSchemas = new HashMap<>();
		Map<String, String> postRenameSchemas = new HashMap<>();
		Map<String, String> restoreRenamedSchemas = new HashMap<>();

		// Para cada schema sendo restaurado
		for (String originalSchemaName : restoreSchemas.keySet()) {
			// Verificamos o nome de destino do schema. Lembrando que o usuário pode escolher para qual schema o backup será restaurado.
			// Isso significa que o originalSchemaName (nome do schema no backup) pode ser diferente do finalSchemaName (nome do schem depois de restaurado).
			String finalSchemaName = restoreSchemas.get(originalSchemaName);

			if (databaseSchemas.contains(finalSchemaName)) {
				String aux = "_" + finalSchemaName + "_" + currentTimestamp;
				preRenameSchemas.put(finalSchemaName, aux);
				deleteSchemas.put(finalSchemaName, aux);
			}

			if (!originalSchemaName.equals(finalSchemaName)) {
				postRenameSchemas.put(originalSchemaName, finalSchemaName);
			}
		}

		for (String originalSchemaName : restoreSchemas.keySet()) {
			// Verifica se o schema está atrapalhando alguma importação. Neste caso, renomeia temporariamente.
			// Se o schema estiver na lista de schemas a serem deletados, não se preocupar em renomear e restaurar
			if (!deleteSchemas.containsKey(originalSchemaName) && databaseSchemas.contains(originalSchemaName)) {
				String aux = "_" + originalSchemaName + "_" + currentTimestamp;
				preRenameSchemas.put(originalSchemaName, aux);
				restoreRenamedSchemas.put(aux, originalSchemaName);
			}
		}

		String globalSchema = Constants.GLOBAL_SCHEMA;

		if (dto.isPurgeAll()) {
			for (String remainingSchema : databaseSchemas) {
				if (remainingSchema.equals("public")) {
					continue;
				}

				if (remainingSchema.equals(globalSchema)) {
					continue;
				}

				if (!deleteSchemas.containsKey(remainingSchema)) {
					deleteSchemas.put(remainingSchema, remainingSchema);
				}
			}
		}

		boolean transactional = true;

		ProcessBuilder pb = _createProcessBuilder(transactional);

		BufferedWriter bw = null;

		try {
			State.writeLog("Starting psql");

			Process p = pb.start();

			_connectOutputToStateLogger(p);

			OutputStreamWriter osw = new OutputStreamWriter(
					p.getOutputStream(), Constants.DEFAULT_CHARSET);

			bw = new BufferedWriter(osw);

			_processRenames(preRenameSchemas, bw);

			bw.flush();

			String extension = _getExtension(dto);

			if (restoreSchemas.containsKey(globalSchema)) {
				State.writeLog("Processing schema for '" + globalSchema + "'");
				processRestore(new File(path, globalSchema + ".schema." + extension), bw);

				State.writeLog("Processing data for '" + globalSchema + "'");
				processRestore(new File(path, globalSchema + ".data." + extension), bw);

				bw.flush();
			}

			for (String schema : restoreSchemas.keySet()) {
				if (!globalSchema.equals(schema)) {
					_processSchema(path, extension, schema, bw);

					bw.flush();
				}
			}

			_processRenames(postRenameSchemas, bw);

			bw.flush();

			_processRenames(restoreRenamedSchemas, bw);

			bw.flush();

			// Postprocessing deletes
			for (String originalSchemaName : deleteSchemas.keySet()) {
				String schemaToBeDeleted = deleteSchemas.get(originalSchemaName);

				State.writeLog("Droping schema " + schemaToBeDeleted);

				if (!originalSchemaName.equals(globalSchema)) {
					_writeLine(
						bw,
						String.format(
							"DELETE FROM \"%s\".digital_media;",
							schemaToBeDeleted));
				}

				_writeLine(
					bw,
					String.format(
						"DROP SCHEMA \"%s\" CASCADE;", schemaToBeDeleted));

				if (!originalSchemaName.equals(globalSchema)) {
					_writeLine(
						bw,
						String.format(
							_DELETE_SCHEMA_TPL, globalSchema,
							originalSchemaName));
				}
			}

			bw.flush();

			for (String originalSchemaName : restoreSchemas.keySet()) {
				String finalSchemaName = restoreSchemas.get(originalSchemaName);

				if (!finalSchemaName.equals(globalSchema)) {
					String schemaTitle = finalSchemaName;

					schemaTitle = dto.getSchemas().get(originalSchemaName).getLeft();
					schemaTitle = schemaTitle.replaceAll("'", "''").replaceAll("\\\\", "\\\\");

					_writeLine(
						bw,
						String.format(
							_DELETE_SCHEMA_TPL, globalSchema, finalSchemaName));

					_writeLine(
						bw,
						_buildInsertSchemaQuery(finalSchemaName, schemaTitle));
				}
			}

			_writeLine(bw, _DELETE_FROM_SCHEMAS);

			_writeLine(bw, "ANALYZE");

			bw.close();

			p.waitFor();

			return p.exitValue() == 0;
		} catch (IOException e) {
			logger.error(e.getMessage(), e);
		} catch (InterruptedException e) {
			logger.error(e.getMessage(), e);
		} finally {
			IOUtils.closeQuietly(bw);
		}

		return false;
	}

	private String _buildInsertSchemaQuery(String finalSchemaName, String schemaTitle) {
		return String.format(_INSERT_SCHEMA_TPL, finalSchemaName, schemaTitle);
	}

	private void _processSchema(File path, String extension, String schema, BufferedWriter bw) throws IOException {
		// Restoring database schema (creating tables and indexes)
		State.writeLog("Processing schema for '" + schema + "'");
		processRestore(new File(path, schema + ".schema." + extension), bw);

		// Restoring database data
		State.writeLog("Processing data for '" + schema + "'");
		processRestore(new File(path, schema + ".data." + extension), bw);

		// Restoring digital media files
		State.writeLog("Processing media for '" + schema + "'");
		this.processMediaRestore(new File(path, schema + ".media." + extension), bw, schema);
		this.processMediaRestoreFolder(new File(path, schema), bw);
	}

	private static void _processRenames(
		Map<String, String> preRenameSchemas, BufferedWriter bw) {

		preRenameSchemas.forEach((originalSchemaName, finalSchemaName) -> {
			State.writeLog(
				String.format("Renaming schema %s to %s", originalSchemaName,
					finalSchemaName));

			_writeLine(
				bw,
				String.format(
					_ALTER_SCHEMA_TPL, originalSchemaName, finalSchemaName));
		});
	}

	private void _validateRestoreSchemas(Map<String, String> restoreSchemas) {
		if (restoreSchemas == null || restoreSchemas.size() == 0) {
			throw new ValidationException(
				"administration.maintenance.backup.error.no_schema_selected");
		}
	}

	public synchronized boolean recreateBiblivre3RestoreDatabase(
		boolean tryPGSQL92)
		throws IOException {

		boolean transactional = false;

		ProcessBuilder pb = _createProcessBuilder(transactional);

		Process p;

		p = pb.start();

		try (BufferedWriter bw =
			new BufferedWriter(
				new OutputStreamWriter(
					p.getOutputStream(), Constants.DEFAULT_CHARSET))) {

			_connectOutputToStateLogger(p);

			_terminateBackendProcess(tryPGSQL92, bw);

			_dropExistingV3Database(bw);

			_createV3Database(bw);

			bw.close();

			p.waitFor();

			return p.exitValue() == 0;
		} catch (InterruptedException e) {
			logger.error(e.getMessage(), e);
		}

		return false;
	}

	private void _createV3Database(BufferedWriter bw) {
		_writeLine(bw, _CREATE_RESTORE_DATABASE);
	}

	private void _dropExistingV3Database(BufferedWriter bw) throws IOException {
		_writeLine(bw, _DROP_RESTORE_DATABASE);
	}

	private void _terminateBackendProcess(boolean tryPGSQL92, BufferedWriter bw) {
		if (tryPGSQL92) {
			_writeLine(bw, _TERMINATE_BACKEND_92);
		} else {
			_writeLine(bw, _TERMINATE_BACKEND);
		}
	}

	private void _connectOutputToStateLogger(Process p) {
		InputStreamReader input =
			new InputStreamReader(
				p.getInputStream(), Constants.DEFAULT_CHARSET);

		Executor executor = Executors.newSingleThreadScheduledExecutor();

		executor.execute(() -> {
			String outputLine;

			try (BufferedReader br = new BufferedReader(input)) {
				while ((outputLine = br.readLine()) != null) {
					State.writeLog(outputLine);
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		});
	}

	public synchronized boolean restoreBackupBiblivre3(File sql) {
		boolean transactional = true;

		ProcessBuilder pb = _createProcessBuilder(transactional);

		try {
			Process p = pb.start();

			OutputStreamWriter writer = new OutputStreamWriter(
					p.getOutputStream(), Constants.DEFAULT_CHARSET);

			final BufferedWriter bw = new BufferedWriter(writer);

			_connectOutputToStateLogger(p);

			_validateBackup(sql);

			Files.lines(sql.toPath())
				.filter(StringUtils::isNotBlank)
				.filter(RestoreBO::_isNotCommentLine)
				.filter(RestoreBO::_isNotProceduralLanguageStatement)
				.filter(RestoreBO::_isNotDatabaseStatement)
				.map(RestoreBO::_replaceDatabaseConnection)
				.map(RestoreBO::_replaceUserIfGrantingOrRevoking)
				.map(RestoreBO::_removeLCProperties)
				.forEach(line -> {
					_writeLine(bw, line);
				});

			bw.close();

			p.waitFor();

			return p.exitValue() == 0;
		} catch (IOException e) {
			logger.error(e.getMessage(), e);
		} catch (InterruptedException e) {
			logger.error(e.getMessage(), e);
		}

		return false;
	}

	public RestoreDTO getRestoreDTO(String filename) {
		BackupBO backupBO = BackupBO.getInstance(this.getSchema());

		File path = backupBO.getBackupDestination();

		if (path == null) {
			path = FileUtils.getTempDirectory();
		}

		File backup = new File(path, filename);
		if (!backup.exists()) {
			throw new ValidationException("administration.maintenance.backup.error.backup_file_not_found");
		}

		RestoreDTO dto = this.getRestoreDTO(backup);

		if (dto == null || !dto.isValid()) {
			throw new ValidationException("administration.maintenance.backup.error.corrupted_backup_file");
		}

		return dto;
	}

	private RestoreDTO getRestoreDTO(File file) {
		ZipFile zip = null;
		InputStream content = null;
		RestoreDTO dto = null;

		try {
			zip = new ZipFile(file);
			ZipArchiveEntry metadata = zip.getEntry("backup.meta");

			if (metadata == null || !zip.canReadEntryData(metadata)) {
				return null;
			}

			StringWriter writer = new StringWriter();
			content = zip.getInputStream(metadata);
			IOUtils.copy(content, writer, Constants.DEFAULT_CHARSET);

			JSONObject json = new JSONObject(writer.toString());
			dto = new RestoreDTO(json);
		} catch (Exception e) {
			dto = new RestoreDTO();
			dto.setValid(false);
		} finally {
			if (dto != null) {
				dto.setBackup(file);
			}

			ZipFile.closeQuietly(zip);
			IOUtils.closeQuietly(content);
		}

		return dto;
	}

	public static void processRestore(File restore, BufferedWriter bw) throws IOException {
		if (restore == null) {
			logger.info("===== Skipping File 'null' =====");
			return;
		}

		if (!restore.exists()) {
			logger.info("===== Skipping File '" + restore.getName() + "' =====");
			return;
		}

		logger.info("===== Restoring File '" + restore.getName() + "' =====");

		BufferedReader reader =
			new BufferedReader(
				new InputStreamReader(new FileInputStream(restore), "UTF-8"));

		reader.lines()
			.filter(StringUtils::isNotBlank)
			.filter(RestoreBO::_isNotCommentLine)
			.filter(RestoreBO::_isNotReferringToGlobalUnlink)
			.forEach(line -> {
				_writeLine(bw, line);
				State.incrementCurrentStep();
			});

		bw.flush();

		reader.close();
	}

	private static boolean _isNotCommentLine(String line) {
		return !line.trim().startsWith("--");
	}

	private static boolean _isNotReferringToGlobalUnlink(String line) {
		return !line.contains("global.unlink");
	}

	private void processMediaRestoreFolder(File path, BufferedWriter bw) throws IOException {
		if (path == null) {
			logger.info("===== Skipping File 'null' =====");
			return;
		}

		if (!path.exists() || !path.isDirectory()) {
			logger.info("===== Skipping File '" + path.getName() + "' =====");
			return;
		}

		DigitalMediaDAO dao = DigitalMediaDAO.getInstance(Constants.GLOBAL_SCHEMA);

		for (File file : path.listFiles()) {
			Matcher fileMatcher = _FILE.matcher(file.getName());

			if (fileMatcher.find()) {
				String mediaId = fileMatcher.group(1);

				long oid = dao.importFile(file);

				String newLine = _buildUpdateDigitalMediaQuery(mediaId, oid);

				_writeLine(bw, newLine);
			}
		}
	}

	private String _buildUpdateDigitalMediaQuery(String mediaId, long oid) {
		return String.format(_UPDATE_DIGITALMEDIA_TPL, oid, mediaId);
	}

	private void processMediaRestore(File restore, BufferedWriter bw, String schema) 
		throws RestoreException {

		if (restore == null) {
			logger.info("===== Skipping File 'null' =====");
			return;
		}

		if (!restore.exists()) {
			logger.info("===== Skipping File '" + restore.getName() + "' =====");
			return;
		}

		logger.info("===== Restoring File '" + restore.getName() + "' =====");

		try {
			// Since PostgreSQL uses global OIDs for LargeObjects, we can't simply
			// restore a digital_media backup. To prevent oid conflicts, we will create
			// a new oid, replacing the old one.
	
			Map<Long, Long> oidMap = new HashMap<>();

			Files.lines(restore.toPath())
				.forEach(line -> {
					State.incrementCurrentStep();

					_processLOLine(line, oidMap, bw);
				});

			bw.flush();

			_writeLine(bw, "SET search_path = \"" + schema + "\", pg_catalog;");
	
			oidMap.forEach((oid, newOid) -> {
				String query = _buildUpdateDigitalMediaQuery(oid, newOid);

				_writeLine(bw, query);
			});
	
			bw.flush();
		} catch (Exception e) {
			throw new RestoreException(e);
		}
	}

	private void _processLOLine(
		String line, Map<Long, Long> oidMap, BufferedWriter bw) {

		if (line.startsWith("SELECT pg_catalog.lo_create")) {
			// New OID detected

			_processNewOid(line, oidMap);
		}
		else if (line.startsWith("SELECT pg_catalog.lo_open")) {
			// Opening the Large Object for writing purposes

			_processsOpenOid(line, oidMap, bw);
		}
		else if (!_ignoreLine(line)){
			if (line.startsWith("COPY")) {
				logger.info(line);
			}

			_writeLine(bw, line);
		}
	}

	private static void _processsOpenOid(String line, Map<Long, Long> oidMap, BufferedWriter bw) {
		Matcher loOpenMatcher = _LO_OPEN.matcher(line);

		if (loOpenMatcher.find()) {
			Long oid = Long.valueOf(loOpenMatcher.group(2));

			String newLine =
				loOpenMatcher.replaceFirst("$1" + oidMap.get(oid) + "$3");

			_writeLine(bw, newLine);
		}
	}

	private void _processNewOid(String line, Map<Long, Long> oidMap) {
		Matcher loCreateMatcher = _LO_CREATE.matcher(line);

		if (loCreateMatcher.find()) {
			Long currentOid = Long.valueOf(loCreateMatcher.group(1));

			Long newOid = digitalMediaDAO.createOID();

			logger.info(
				"Creating new OID (old: " + currentOid + ", new: "
					+ newOid + ")");

			oidMap.put(currentOid, newOid);
		}
	}

	private static boolean _ignoreLine(String line) {
		return line.startsWith("ALTER LARGE OBJECT") ||
			line.startsWith("BEGIN;") || line.startsWith("COMMIT;");
	}

	private static String _buildUpdateDigitalMediaQuery(long oid, long newOid) {
		return String.format(_UPDATE_DIGITALMEDIA_BLOB_TPL, newOid, oid);
	}


	private static boolean _isNotProceduralLanguageStatement(String line) {
		return !line.startsWith("CREATE PROCEDURAL LANGUAGE") &&
			!line.startsWith("ALTER PROCEDURAL LANGUAGE");
	}

	private static boolean _isNotDatabaseStatement(String line) {
		return !line.startsWith("CREATE DATABASE") &&
			!line.startsWith("ALTER DATABASE");
	}

	private static String _replaceUserIfGrantingOrRevoking(String line) {
		if (line.startsWith("GRANT") || line.startsWith("REVOKE")) {
			return line.replace(
				"postgres", DatabaseUtils.getDatabaseUsername());
		}

		return line;
	}

	private static String _replaceDatabaseConnection(String line) {
		if (line.startsWith("\\connect")) {
			return "\\connect biblivre4_b3b_restore\n";
		}

		return line;
	}

	private static void _validateBackup(File sql) throws IOException {
		boolean validBackup = Files.lines(sql.toPath())
			.map(String::trim)
			.anyMatch(line -> line.startsWith("\\connect biblivre"));

		if (!validBackup) {
			State.writeLog("Never reached \\connect biblivre;");
			throw new ValidationException("administration.maintenance.backup.error.corrupted_backup_file");
		}
	}

	private static String _removeLCProperties(String line) {
		return line
			.replaceAll("LC_COLLATE = '[^']*'", StringPool.BLANK)
			.replaceAll("LC_CTYPE = '[^']*'", StringPool.BLANK);
	}

	private ProcessBuilder _createProcessBuilder(boolean transactional) {
		File psql = DatabaseUtils.getPsql(this.getSchema());

		if (psql == null) {
			throw new ValidationException("administration.maintenance.backup.error.psql_not_found");
		}

		String[] commands;

		if (transactional) {
			commands = new String[] {
				psql.getAbsolutePath(),
				"--single-transaction",
				"--host",
				DatabaseUtils.getDatabaseHostName(),
				"--port",
				DatabaseUtils.getDatabasePort(),
				"-v",
				"ON_ERROR_STOP=1",
				"--file",
				"-",
			};
		}
		else {
			commands = new String[] {
				psql.getAbsolutePath(),
				"--host",
				DatabaseUtils.getDatabaseHostName(),
				"--port",
				DatabaseUtils.getDatabasePort(),
				"-v",
				"ON_ERROR_STOP=1",
				"--file",
				"-",
			};
		}

		ProcessBuilder pb = new ProcessBuilder(commands);

		pb.redirectErrorStream(true);

		return pb;
	}

	private static void _countRestoreSteps(RestoreDTO dto, File tmpDir, String extension) {
		long steps = 0;

		for (String schema : dto.getRestoreSchemas().keySet()) {
			steps += FileIOUtils.countLines(new File(tmpDir, schema + ".schema." + extension));
			steps += FileIOUtils.countLines(new File(tmpDir, schema + ".data." + extension));

			if (!schema.equals(Constants.GLOBAL_SCHEMA)) {
				steps += FileIOUtils.countLines(new File(tmpDir, schema + ".media." + extension));
			}
		}

		State.setSteps(steps);
		State.writeLog("Restoring " + dto.getRestoreSchemas().size() + " schemas for a total of " + steps + " SQL lines");
	}

	private static void _movePartialFiles(RestoreDTO partial, File tmpDir) {
		try {
			File partialTmpDir = FileIOUtils.unzip(partial.getBackup());

			for (File partialFile : partialTmpDir.listFiles()) {
				if (partialFile.getName().equals("backup.meta")) {
					FileUtils.deleteQuietly(partialFile);
				} else if (partialFile.isDirectory()) {
					FileUtils.moveDirectoryToDirectory(partialFile, tmpDir, true);
				} else {
					FileUtils.moveFileToDirectory(partialFile, tmpDir, true);
				}
			}

			FileUtils.deleteQuietly(partialTmpDir);
		} catch (Exception e) {
			throw new ValidationException("administration.maintenance.backup.error.couldnt_unzip_backup", e);
		}
	}

	private static void _sortRestores(List<RestoreDTO> list) {
		Collections.sort(list, (restore1, restore2) -> {
			if (restore2 == null) {
				return -1;
			}

			if (restore1.getCreated() != null && restore2.getCreated() != null) {
				return restore2.getCreated().compareTo(restore1.getCreated()); // Order Desc
			}

			if (restore1.getBackup() != null && restore2.getBackup() != null) {
				return restore1.getBackup().getName().compareTo(restore2.getBackup().getName());
			}

			return 0;
		});
	}

	private static void _validateFile(File gzipFile) {
		if (gzipFile == null || !gzipFile.exists()) {
			throw new ValidationException(
				"administration.maintenance.backup.error."
					+ "corrupted_backup_file");
		}
	}

	private static boolean _verifyDTO(RestoreDTO dto) {
		return dto.isValid() && dto.getBackup() != null &&
			dto.getBackup().exists();
	}

	private static String _getExtension(RestoreDTO dto) {
		return (dto.getBackup().getPath().endsWith("b5bz")) ? "b5b" : "b4b";
	}

	private static void _writeLine(BufferedWriter bw, String newLine) {
		try {
			bw.write(newLine);
			bw.newLine();
		}
		catch (IOException ioe) {
			throw new RestoreException(ioe);
		}
	}
}
