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

import biblivre.core.AbstractBO;
import biblivre.core.SchemaThreadLocal;
import biblivre.core.configurations.Configurations;
import biblivre.core.file.BiblivreFile;
import biblivre.core.schemas.Schemas;
import biblivre.core.utils.Constants;
import biblivre.core.utils.DatabaseUtils;
import biblivre.core.utils.FileIOUtils;
import biblivre.core.utils.PgDumpCommand;
import biblivre.core.utils.PgDumpCommand.Format;
import biblivre.core.utils.TextUtils;
import biblivre.digitalmedia.DigitalMediaBO;
import biblivre.digitalmedia.DigitalMediaDTO;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Writer;
import java.net.InetSocketAddress;
import java.util.ArrayList;
import java.util.Date;
import java.util.Formatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.output.FileWriterWithEncoding;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BackupBO extends AbstractBO {
    private BackupDAO backupDAO;
    private DigitalMediaBO digitalMediaBO;

    public void simpleBackup() {
        BackupType backupType = BackupType.FULL;
        BackupScope backupScope = this.getBackupScope();

        ArrayList<String> list = new ArrayList<>();
        list.add(Constants.GLOBAL_SCHEMA);

        String schema = SchemaThreadLocal.get();

        if (Constants.GLOBAL_SCHEMA.equals(schema)) {
            list.addAll(Schemas.getEnabledSchemasList());
        } else {
            list.add(schema);
        }

        Map<String, Pair<String, String>> map = new HashMap<>();

        for (String s : list) {
            if (Schemas.isNotLoaded(s)) {
                continue;
            }

            String title = Configurations.getString(Constants.CONFIG_TITLE);
            String subtitle = Configurations.getString(Constants.CONFIG_SUBTITLE);
            map.put(s, Pair.of(title, subtitle));
        }

        BackupDTO dto = this.prepare(map, backupType, backupScope);
        this.backup(dto);
    }

    public BackupScope getBackupScope() {
        String schema = SchemaThreadLocal.get();

        if (Constants.GLOBAL_SCHEMA.equals(schema)) {
            return BackupScope.MULTI_SCHEMA;
        } else if (Schemas.isMultipleSchemasEnabled()) {
            return BackupScope.SINGLE_SCHEMA_FROM_MULTI_SCHEMA;
        } else {
            return BackupScope.SINGLE_SCHEMA;
        }
    }

    public BackupDTO prepare(
            Map<String, Pair<String, String>> schemas, BackupType type, BackupScope scope) {
        BackupDTO dto = new BackupDTO(schemas, type, scope);
        dto.setCurrentStep(0);

        int steps = 0;
        int schemasCount = dto.getSchemas().size();

        switch (dto.getType()) {
            case FULL:
                // schema, data and media for each schema (except media for public) + zip
                steps = schemasCount * 3;
                break;
            case EXCLUDE_DIGITAL_MEDIA:
                // schema and data for each schema + zip
                steps = (schemasCount * 2) + 1;
                break;
            case DIGITAL_MEDIA_ONLY:
                // media for each schema (except for public) + zip
                steps = schemasCount;
                break;
        }

        dto.setSteps(steps);

        if (this.save(dto)) {
            return dto;
        } else {
            return null;
        }
    }

    public void backup(BackupDTO dto) {
        try {
            this.createBackup(dto);

            if (dto.getBackup() != null) {
                this.move(dto);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void createBackup(BackupDTO dto) throws IOException {
        File pgdump = DatabaseUtils.getPgDump();

        if (pgdump == null) {
            return;
        }

        File tmpDir = FileIOUtils.createTempDir();

        Map<String, Pair<String, String>> schemas = dto.getSchemas();
        BackupType type = dto.getType();

        // Writing metadata
        File meta = new File(tmpDir, "backup.meta");
        Writer writer = new FileWriterWithEncoding(meta, Constants.DEFAULT_CHARSET);
        writer.write(new RestoreDTO(dto).toJSONString());
        writer.flush();
        writer.close();

        for (String schema : schemas.keySet()) {
            if (type == BackupType.FULL || type == BackupType.EXCLUDE_DIGITAL_MEDIA) {
                dumpSchema(dto, tmpDir, schema);

                dumpData(dto, tmpDir, schema);
            }

            if (!schema.equals(Constants.GLOBAL_SCHEMA)) {
                if (type == BackupType.FULL || type == BackupType.DIGITAL_MEDIA_ONLY) {
                    dumpMedia(dto, tmpDir, schema);
                }
            }
        }

        File tmpZip = new File(tmpDir.getAbsolutePath() + ".b5bz");

        FileIOUtils.zipFolder(tmpDir, tmpZip);
        FileUtils.deleteQuietly(tmpDir);

        dto.increaseCurrentStep();
        this.save(dto);

        dto.setBackup(tmpZip);
    }

    public BackupDTO get(Integer id) {
        return this.backupDAO.get(id);
    }

    public List<BackupDTO> list() {
        return this.backupDAO.list();
    }

    public BackupDTO getLastBackup() {
        List<BackupDTO> list = this.backupDAO.list(1);

        if (list.size() == 0) {
            return null;
        }

        return list.get(0);
    }

    public boolean save(BackupDTO dto) {
        return this.backupDAO.save(dto);
    }

    public boolean move(BackupDTO dto) {
        File destination = this.getBackupDestination();
        File backup = dto.getBackup();

        if (destination == null) {
            destination = backup.getParentFile();
        }

        StringBuilder sb = new StringBuilder();

        // Format: Biblivre Backup 2012-09-08 12h01m22s Full.b5bz
        Formatter formatter = new Formatter(sb);
        formatter.format(
                "Biblivre Backup %1$tY-%1$tm-%1$td %1$tHh%1$tMm%1$tSs %2$s.b5bz",
                new Date(), StringUtils.capitalize(dto.getType().toString()));
        formatter.close();

        File movedBackup = new File(destination, sb.toString());

        boolean success = backup.renameTo(movedBackup);

        if (success) {
            dto.setBackup(movedBackup);
        }

        return this.save(dto);
    }

    public String getBackupPath() {
        String path = Configurations.getString(Constants.CONFIG_BACKUP_PATH);

        if (StringUtils.isBlank(path) || FileIOUtils.doesNotExists(path)) {
            File home = new File(System.getProperty("user.home"));
            File biblivre = new File(home, "Biblivre");

            if (!biblivre.exists() && home.isDirectory() && home.canWrite()) {
                biblivre.mkdir();
            }

            path = biblivre.getAbsolutePath();
        }

        return path;
    }

    public File getBackupDestination() {
        String path = this.getBackupPath();

        return FileIOUtils.getWritablePath(path);
    }

    private boolean exportDigitalMedia(String schema, File path) {
        List<DigitalMediaDTO> list = digitalMediaBO.list();

        for (DigitalMediaDTO dto : list) {
            BiblivreFile file = digitalMediaBO.load(dto.getId(), dto.getName());
            File destination =
                    new File(
                            path,
                            dto.getId()
                                    + "_"
                                    + TextUtils.removeNonLettersOrDigits(dto.getName(), "-"));
            try (OutputStream writer = new FileOutputStream(destination)) {
                file.copy(writer);

                file.close();
            } catch (IOException ioException) {
                logger.error("error while exporting digital media", ioException);

                return false;
            }
        }

        return true;
    }

    private boolean dumpDatabase(ProcessBuilder pb) {
        pb.redirectErrorStream(true);

        try {
            Process p = pb.start();

            try (InputStreamReader isr = new InputStreamReader(p.getInputStream());
                    BufferedReader br = new BufferedReader(isr)) {
                String line;

                while ((line = br.readLine()) != null) {
                    // There was a system.out.println here for the 'line' var,
                    // with a FIX_ME tag.  So I changed it to logger.debug().
                    if (logger.isDebugEnabled()) {
                        logger.debug(line);
                    }
                }

                p.waitFor();

                return p.exitValue() == 0;
            }
        } catch (IOException e) {
            logger.error(e.getMessage(), e);
        } catch (InterruptedException e) {
            logger.error(e.getMessage(), e);
        }

        return false;
    }

    private void dumpDatabase(PgDumpCommand command) {
        this.dumpDatabase(new ProcessBuilder(command.getCommands()));
    }

    private void dump(
            BackupDTO dto,
            String schema,
            File backupFile,
            boolean isSchemaOnly,
            boolean isDataOnly,
            String excludeTablePattern,
            String includeTablePattern) {

        File pgdump = DatabaseUtils.getPgDump();

        InetSocketAddress defaultAddress =
                new InetSocketAddress(
                        DatabaseUtils.getDatabaseHostName(),
                        Integer.parseInt(DatabaseUtils.getDatabasePort()));

        Format defaultFormat = Format.PLAIN;

        this.dumpDatabase(
                new PgDumpCommand(
                        pgdump,
                        defaultAddress,
                        Constants.DEFAULT_CHARSET,
                        defaultFormat,
                        schema,
                        backupFile,
                        isSchemaOnly,
                        isDataOnly,
                        excludeTablePattern,
                        includeTablePattern));

        dto.increaseCurrentStep();
        this.save(dto);
    }

    private void dumpData(BackupDTO dto, File tmpDir, String schema) {
        File dataBackup = new File(tmpDir, schema + ".data.b5b");
        boolean isSchemaOnly = false;
        boolean isDataOnly = true;
        String excludeTablePattern = schema + ".digital_media";
        String includeTablePattern = null;

        dump(
                dto,
                schema,
                dataBackup,
                isSchemaOnly,
                isDataOnly,
                excludeTablePattern,
                includeTablePattern);
    }

    private void dumpSchema(BackupDTO dto, File tmpDir, String schema) {
        File schemaBackup = new File(tmpDir, schema + ".schema.b5b");
        boolean isSchemaOnly = true;
        boolean isDataOnly = false;
        String excludeTablePattern = null;
        String includeTablePattern = null;

        dump(
                dto,
                schema,
                schemaBackup,
                isSchemaOnly,
                isDataOnly,
                excludeTablePattern,
                includeTablePattern);
    }

    private void dumpMedia(BackupDTO dto, File tmpDir, String schema) throws IOException {
        File mediaBackup = new File(tmpDir, schema + ".media.b5b");
        boolean isSchemaOnly = false;
        boolean isDataOnly = true;
        String excludeTablePattern = null;
        String includeTablePattern = schema + ".digital_media";

        dump(
                dto,
                schema,
                mediaBackup,
                isSchemaOnly,
                isDataOnly,
                excludeTablePattern,
                includeTablePattern);

        File schemaBackup = new File(tmpDir, schema);
        schemaBackup.mkdir();
        this.exportDigitalMedia(schema, schemaBackup);
        this.save(dto);
    }

    protected static final Logger logger = LoggerFactory.getLogger(BackupBO.class);

    public Set<String> listDatabaseSchemas() {
        return backupDAO.listDatabaseSchemas();
    }

    @Autowired
    public void setBackupDAO(BackupDAO backupDAO) {
        this.backupDAO = backupDAO;
    }

    @Autowired
    public void setDigitalMediaBO(DigitalMediaBO digitalMediaBO) {
        this.digitalMediaBO = digitalMediaBO;
    }
}
