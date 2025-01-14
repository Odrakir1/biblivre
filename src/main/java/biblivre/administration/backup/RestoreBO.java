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

import biblivre.administration.backup.exception.RestoreException;
import biblivre.administration.setup.State;
import biblivre.core.AbstractBO;
import biblivre.core.SchemaThreadLocal;
import biblivre.core.UpdatesDAO;
import biblivre.core.exceptions.ValidationException;
import biblivre.core.utils.Constants;
import biblivre.core.utils.DatabaseUtils;
import biblivre.core.utils.FileIOUtils;
import biblivre.database.util.PostgreSQLStatementIterable;
import biblivre.digitalmedia.DigitalMediaDAO;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress.archivers.zip.ZipFile;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class RestoreBO extends AbstractBO {
    private static final String[] FILTERED_OUT_STATEMENT_PREFIXES =
            new String[] {"CREATE FUNCTION", "ALTER FUNCTION", "CREATE TRIGGER"};

    private static final class BufferedReaderIterator implements Iterator<Character> {
        private final BufferedReader bufferedReader;
        int read;

        private BufferedReaderIterator(BufferedReader bufferedReader) throws IOException {
            this.bufferedReader = bufferedReader;

            read = bufferedReader.read();
        }

        @Override
        public Character next() {
            char c = (char) read;

            try {
                read = bufferedReader.read();
            } catch (IOException ioException) {
                logger.error("error while reading script", ioException);

                read = -1;
            }

            return c;
        }

        @Override
        public boolean hasNext() {
            return read != -1;
        }
    }

    private static final String _DROP_SCHEMA_TPL = "DROP SCHEMA \"%s\" CASCADE;";
    private static final String _DELETE_DIGITALMDIA_TPL = "DELETE FROM \"%s\".digital_media;";
    private static final String _UPDATE_DIGITALMEDIA_BLOB_TPL =
            "UPDATE digital_media SET blob = '%d' WHERE blob = '%d';";
    private static final Pattern _FILE = Pattern.compile("^(\\d+)_(.*)$");
    private static final String _UPDATE_DIGITALMEDIA_TPL =
            "UPDATE digital_media SET blob = '%d' WHERE id = '%s';";
    private static final String _ALTER_SCHEMA_TPL = "ALTER SCHEMA \"%s\" RENAME TO \"%s\";";
    private static final String _DELETE_SCHEMA_TPL =
            "DELETE FROM \"global\".schemas WHERE \"schema\" = '%s';";
    private static final String _INSERT_SCHEMA_TPL =
            "INSERT INTO \"global\".schemas (schema, name) VALUES ('%s', E'%s');";
    private static final String _DELETE_FROM_SCHEMAS =
            "DELETE FROM \"global\".schemas WHERE \"schema\" not in (SELECT schema_name FROM information_schema.schemata);";
    private static final Pattern _LO_OPEN = Pattern.compile("(.*lo_open\\(')(.*?)(',.*)");

    private static final Pattern _LO_CREATE = Pattern.compile("lo_create\\('(.*?)'\\)");

    private static final String[] _BACKUP_EXTENSIONS = new String[] {"b4bz", "b5bz"};

    private static final Logger logger = LoggerFactory.getLogger(RestoreBO.class);

    private DigitalMediaDAO digitalMediaDAO;

    private BackupBO backupBO;

    public List<RestoreDTO> list() {
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
                        .map(RestoreBO::toRestoreDTO)
                        .filter(RestoreDTO::isValid)
                        .collect(Collectors.toList());

        _sortRestores(list);

        return list;
    }

    public boolean restore(RestoreDTO dto, RestoreDTO partial) throws IOException {

        if (!_verifyDTO(dto)) {
            throw new ValidationException(
                    "administration.maintenance.backup.error." + "corrupted_backup_file");
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

    public RestoreDTO getRestoreDTO(String filename) {
        File path = backupBO.getBackupDestination();

        if (path == null) {
            path = FileUtils.getTempDirectory();
        }

        File backup = new File(path, filename);
        if (!backup.exists()) {
            throw new ValidationException(
                    "administration.maintenance.backup.error.backup_file_not_found");
        }

        RestoreDTO dto = toRestoreDTO(backup);

        if (dto == null || !dto.isValid()) {
            throw new ValidationException(
                    "administration.maintenance.backup.error.corrupted_backup_file");
        }

        return dto;
    }

    public static void processRestore(File restore) throws IOException {

        if (restore == null) {
            logger.info("===== Skipping File 'null' =====");
            return;
        }

        if (!restore.exists()) {
            logger.info("===== Skipping File '" + restore.getName() + "' =====");
            return;
        }

        logger.info("===== Restoring File '" + restore.getName() + "' =====");

        try (BufferedReader bufferedReader = Files.newBufferedReader(restore.toPath())) {
            PostgreSQLStatementIterable postgreSQLStatementIterable =
                    new PostgreSQLStatementIterable(new BufferedReaderIterator(bufferedReader));

            postgreSQLStatementIterable.stream()
                    .filter(RestoreBO::notFunctionOrTriggerRelated)
                    .forEach(
                            statement -> {
                                _writeLine(statement);
                                State.incrementCurrentStep();
                            });
        }
    }

    public static boolean notFunctionOrTriggerRelated(String statement) {
        return Arrays.stream(FILTERED_OUT_STATEMENT_PREFIXES).noneMatch(statement::startsWith);
    }

    @Autowired
    public void setDigitalMediaDAO(DigitalMediaDAO digitalMediaDAO) {
        this.digitalMediaDAO = digitalMediaDAO;
    }

    @Autowired
    public void setBackupBO(BackupBO backupBO) {
        this.backupBO = backupBO;
    }

    private synchronized boolean restoreBackup(RestoreDTO dto, File directory) {
        Map<String, String> restoreSchemas = dto.getRestoreSchemas();

        _validateRestoreSchemas(restoreSchemas);

        RestoreContextHelper context =
                new RestoreContextHelper(dto, backupBO.listDatabaseSchemas());

        String globalSchema = Constants.GLOBAL_SCHEMA;

        boolean transactional = true;

        ProcessBuilder pb = _createProcessBuilder(transactional);

        try {
            State.writeLog("Starting psql");

            Process p = pb.start();

            _connectOutputToStateLogger(p);

            try (BufferedWriter bw = _getBufferedWriter(p)) {

                _processRenames(context.getPreRenameSchemas());

                bw.flush();

                String extension = _getExtension(dto);

                if (restoreSchemas.containsKey(globalSchema)) {
                    _processGlobalSchema(directory, extension);

                    bw.flush();
                }

                for (String schema : restoreSchemas.keySet()) {
                    if (!globalSchema.equals(schema)) {
                        _processSchemaRestores(directory, extension, schema);

                        bw.flush();
                    }
                }

                _processRenames(context.getPostRenameSchemas());

                bw.flush();

                _processRenames(context.getRestoreRenamedSchemas());

                bw.flush();

                _postProcessDeletes(context.getDeleteSchemas(), bw);

                bw.flush();

                _postProcessRenames(dto, restoreSchemas, bw);

                _writeLine(_DELETE_FROM_SCHEMAS);

                _writeLine("ANALYZE");

                bw.close();

                p.waitFor();

                return p.exitValue() == 0;
            }
        } catch (IOException | InterruptedException e) {
            logger.error(e.getMessage(), e);
        }

        return false;
    }

    private BufferedWriter _getBufferedWriter(Process p) {
        OutputStreamWriter osw = new OutputStreamWriter(p.getOutputStream());

        return new BufferedWriter(osw);
    }

    private void _processGlobalSchema(File directory, String extension) throws IOException {
        State.writeLog("Processing schema for 'global'");

        File ddlFile = new File(directory, "global.schema." + extension);

        processRestore(ddlFile);

        State.writeLog("Processing data for 'global'");

        File dmlFile = new File(directory, "global.data." + extension);

        processRestore(dmlFile);
    }

    private static void _postProcessRenames(
            RestoreDTO dto, Map<String, String> restoreSchemas, BufferedWriter bw) {

        restoreSchemas.forEach(
                (originalSchemaName, finalSchemaName) -> {
                    if (!Constants.GLOBAL_SCHEMA.equals(finalSchemaName)) {
                        String schemaTitle;

                        schemaTitle = dto.getSchemas().get(originalSchemaName).getLeft();

                        schemaTitle = schemaTitle.replaceAll("'", "''").replaceAll("\\\\", "\\\\");

                        _writeLine(String.format(_DELETE_SCHEMA_TPL, finalSchemaName));

                        _writeLine(_buildInsertSchemaQuery(finalSchemaName, schemaTitle));
                    }
                });
    }

    private static void _postProcessDeletes(Map<String, String> deleteSchemas, BufferedWriter bw) {

        deleteSchemas.forEach(
                (originalSchemaName, schemaToBeDeleted) -> {
                    State.writeLog("Droping schema " + schemaToBeDeleted);

                    String globalSchema = Constants.GLOBAL_SCHEMA;

                    if (!globalSchema.equals(originalSchemaName)) {
                        _writeLine(String.format(_DELETE_DIGITALMDIA_TPL, schemaToBeDeleted));
                    }

                    _writeLine(String.format(_DROP_SCHEMA_TPL, schemaToBeDeleted));

                    if (!globalSchema.equals(originalSchemaName)) {
                        _writeLine(String.format(_DELETE_SCHEMA_TPL, originalSchemaName));
                    }
                });
    }

    private static String _buildInsertSchemaQuery(String finalSchemaName, String schemaTitle) {

        return String.format(_INSERT_SCHEMA_TPL, finalSchemaName, schemaTitle);
    }

    private void _processSchemaRestores(File path, String extension, String schema)
            throws IOException {

        State.writeLog("Processing schema for '" + schema + "'");

        processRestore(new File(path, schema + ".schema." + extension));

        State.writeLog("Processing data for '" + schema + "'");

        processRestore(new File(path, schema + ".data." + extension));

        State.writeLog("Processing media for '" + schema + "'");

        this.processMediaRestore(new File(path, schema + ".media." + extension), schema);
        this.processMediaRestoreFolder(new File(path, schema));
    }

    private static void _processRenames(Map<String, String> preRenameSchemas) {

        preRenameSchemas.forEach(
                (originalSchemaName, finalSchemaName) -> {
                    State.writeLog(
                            String.format(
                                    "Renaming schema %s to %s",
                                    originalSchemaName, finalSchemaName));

                    _writeLine(
                            String.format(_ALTER_SCHEMA_TPL, originalSchemaName, finalSchemaName));
                });
    }

    private static void _validateRestoreSchemas(Map<String, String> restoreSchemas) {

        if (restoreSchemas == null || restoreSchemas.size() == 0) {
            throw new ValidationException(
                    "administration.maintenance.backup.error.no_schema_selected");
        }
    }

    private void _connectOutputToStateLogger(Process p) {
        Executor executor = Executors.newSingleThreadScheduledExecutor();

        executor.execute(
                () -> {
                    String outputLine;

                    try (InputStreamReader input =
                                    new InputStreamReader(
                                            p.getInputStream(), Constants.DEFAULT_CHARSET);
                            BufferedReader br = new BufferedReader(input)) {
                        while ((outputLine = br.readLine()) != null) {
                            State.writeLog(outputLine);
                        }
                    } catch (Exception e) {
                        logger.error("error while restoring backup", e);
                    }
                });
    }

    private static RestoreDTO toRestoreDTO(File backup) {
        RestoreDTO dto = null;

        try (ZipFile zipFile = new ZipFile(backup)) {
            ZipArchiveEntry metadata = zipFile.getEntry("backup.meta");

            if (metadata == null || !zipFile.canReadEntryData(metadata)) {
                return null;
            }

            try (InputStream content = zipFile.getInputStream(metadata)) {
                StringWriter writer = new StringWriter();

                IOUtils.copy(content, writer, StandardCharsets.UTF_8);

                JSONObject json = new JSONObject(writer.toString());

                dto = new RestoreDTO(json);

                dto.setBackup(backup);
            }
        } catch (Exception e) {
            logger.error("Can't read zip file", e);
            dto = new RestoreDTO();
            dto.setValid(false);
        } finally {
            if (dto != null) {
                dto.setBackup(backup);
            }
        }

        return dto;
    }

    private void processMediaRestoreFolder(File path) {
        if (path == null) {
            logger.info("===== Skipping File 'null' =====");
            return;
        }

        if (!path.exists() || !path.isDirectory()) {
            logger.info("===== Skipping File '" + path.getName() + "' =====");
            return;
        }

        SchemaThreadLocal.withGlobalSchema(
                () -> {
                    for (File file : path.listFiles()) {
                        Matcher fileMatcher = _FILE.matcher(file.getName());

                        if (fileMatcher.find()) {
                            String mediaId = fileMatcher.group(1);

                            long oid = digitalMediaDAO.importFile(file);

                            String newLine = _buildUpdateDigitalMediaQuery(mediaId, oid);

                            _writeLine(newLine);
                        }
                    }

                    return null;
                });
    }

    private String _buildUpdateDigitalMediaQuery(String mediaId, long oid) {
        return String.format(_UPDATE_DIGITALMEDIA_TPL, oid, mediaId);
    }

    private void processMediaRestore(File restore, String schema) throws RestoreException {

        if (restore == null) {
            logger.info("===== Skipping File 'null' =====");
            return;
        }

        if (!restore.exists()) {
            logger.info("===== Skipping File '" + restore.getName() + "' =====");
            return;
        }

        logger.info("===== Restoring File '" + restore.getName() + "' =====");

        try (Stream<String> lines = Files.lines(restore.toPath())) {
            // Since PostgreSQL uses global OIDs for LargeObjects, we can't simply
            // restore a digital_media backup. To prevent oid conflicts, we will create
            // a new oid, replacing the old one.

            Map<Long, Long> oidMap = new HashMap<>();

            lines.forEach(
                    line -> {
                        State.incrementCurrentStep();

                        _processLOLine(line, oidMap);
                    });

            _writeLine("SET search_path = \"" + schema + "\", pg_catalog;");

            oidMap.forEach(
                    (oid, newOid) -> {
                        String query = _buildUpdateDigitalMediaQuery(oid, newOid);

                        _writeLine(query);
                    });
        } catch (Exception e) {
            throw new RestoreException(e);
        }
    }

    private void _processLOLine(String line, Map<Long, Long> oidMap) {

        if (line.startsWith("SELECT pg_catalog.lo_create")) {
            _processNewOid(line, oidMap);
        } else if (line.startsWith("SELECT pg_catalog.lo_open")) {
            _processsOpenOid(line, oidMap);
        } else if (!_ignoreLine(line)) {
            if (line.startsWith("COPY")) {
                logger.info(line);
            }

            _writeLine(line);
        }
    }

    private static void _processsOpenOid(String line, Map<Long, Long> oidMap) {
        Matcher loOpenMatcher = _LO_OPEN.matcher(line);

        if (loOpenMatcher.find()) {
            Long oid = Long.valueOf(loOpenMatcher.group(2));

            String newLine = loOpenMatcher.replaceFirst("$1" + oidMap.get(oid) + "$3");

            _writeLine(newLine);
        }
    }

    private void _processNewOid(String line, Map<Long, Long> oidMap) {
        Matcher loCreateMatcher = _LO_CREATE.matcher(line);

        if (loCreateMatcher.find()) {
            Long currentOid = Long.valueOf(loCreateMatcher.group(1));

            Long newOid = digitalMediaDAO.createOID();

            logger.info("Creating new OID (old: " + currentOid + ", new: " + newOid + ")");

            oidMap.put(currentOid, newOid);
        }
    }

    private static boolean _ignoreLine(String line) {
        return line.startsWith("ALTER LARGE OBJECT")
                || line.startsWith("BEGIN;")
                || line.startsWith("COMMIT;");
    }

    private static String _buildUpdateDigitalMediaQuery(long oid, long newOid) {
        return String.format(_UPDATE_DIGITALMEDIA_BLOB_TPL, newOid, oid);
    }

    private ProcessBuilder _createProcessBuilder(boolean transactional) {
        File psql = DatabaseUtils.getPsql();

        if (psql == null) {
            throw new ValidationException("administration.maintenance.backup.error.psql_not_found");
        }

        String[] commands;

        if (transactional) {
            commands =
                    new String[] {
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
        } else {
            commands =
                    new String[] {
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

    private static void _countRestoreSteps(RestoreDTO dto, File tmpDir, String extension)
            throws IOException {
        long steps = 0;

        for (String schema : dto.getRestoreSchemas().keySet()) {
            steps += FileIOUtils.countLines(new File(tmpDir, schema + ".schema." + extension));
            steps += FileIOUtils.countLines(new File(tmpDir, schema + ".data." + extension));

            if (!schema.equals(Constants.GLOBAL_SCHEMA)) {
                steps += FileIOUtils.countLines(new File(tmpDir, schema + ".media." + extension));
            }
        }

        State.setSteps(steps);
        State.writeLog(
                "Restoring "
                        + dto.getRestoreSchemas().size()
                        + " schemas for a total of "
                        + steps
                        + " SQL lines");
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
            throw new ValidationException(
                    "administration.maintenance.backup.error.couldnt_unzip_backup", e);
        }
    }

    private static void _sortRestores(List<RestoreDTO> list) {
        list.sort(
                (restore1, restore2) -> {
                    if (restore2 == null) {
                        return -1;
                    }

                    if (restore1.getCreated() != null && restore2.getCreated() != null) {
                        return restore2.getCreated().compareTo(restore1.getCreated()); // Order Desc
                    }

                    if (restore1.getBackup() != null && restore2.getBackup() != null) {
                        return restore1.getBackup()
                                .getName()
                                .compareTo(restore2.getBackup().getName());
                    }

                    return 0;
                });
    }

    private static boolean _verifyDTO(RestoreDTO dto) {
        return dto.isValid() && dto.getBackup() != null && dto.getBackup().exists();
    }

    private static String _getExtension(RestoreDTO dto) {
        return dto.getBackup().getPath().endsWith("b5bz") ? "b5b" : "b4b";
    }

    private static void _writeLine(String newLine) {
        UpdatesDAO updatesDAO = UpdatesDAO.getInstance();

        try (Connection con = updatesDAO.beginUpdate()) {
            Statement statement = con.createStatement();

            statement.execute(newLine);

            con.commit();
        } catch (SQLException ioe) {
            throw new RestoreException(ioe);
        }
    }
}
