/*******************************************************************************
 * Este arquivo é parte do Biblivre5.
 *
 * Biblivre5 é um software livre; você pode redistribuí-lo e/ou
 * modificá-lo dentro dos termos da Licença Pública Geral GNU como
 * publicada pela Fundação do Software Livre (FSF); na versão 3 da
 * Licença, ou (caso queira) qualquer versão posterior.
 *
 * Este programa é distribuído na esperança de que possa ser útil,
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
package biblivre.core;

import biblivre.core.utils.Constants;
import biblivre.core.utils.StringPool;
import biblivre.update.UpdateService;
import java.sql.Connection;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class Updates {
    private Map<String, UpdateService> updateServicesMap;

    private static final Logger logger = LoggerFactory.getLogger(Updates.class);

    public static String getVersion() {
        return Constants.BIBLIVRE_VERSION;
    }

    public void globalUpdate() {
        SchemaThreadLocal.withGlobalSchema(
                () -> {
                    UpdatesDAO dao = UpdatesDAO.getInstance();

                    Connection con = null;
                    try {
                        Set<String> installedVersions = dao.getInstalledVersions();

                        for (Entry<String, UpdateService> entry : updateServicesMap.entrySet()) {
                            UpdateService updateService = entry.getValue();

                            String version =
                                    entry.getKey()
                                            .replaceFirst("biblivre.update.", StringPool.BLANK)
                                            .replaceFirst(
                                                    updateService.getClass().getSimpleName(),
                                                    StringPool.BLANK);

                            if (!installedVersions.contains(version)) {
                                logger.info("Processing global update service {}.", version);

                                con = dao.beginUpdate();

                                updateService.doUpdate(con);

                                dao.commitUpdate(version, con);

                                updateService.afterUpdate();
                            } else {
                                logger.info("Skipping global update service {}.", version);
                            }
                        }

                        return true;
                    } catch (Exception e) {
                        dao.rollbackUpdate(con);
                        e.printStackTrace();
                    }

                    return false;
                });
    }

    public void schemaUpdate(String schema) {
        UpdatesDAO dao = UpdatesDAO.getInstance();

        SchemaThreadLocal.withSchema(
                schema,
                () -> {
                    Connection con = null;
                    try {
                        if (!dao.checkTableExistance("versions")) {
                            dao.fixVersionsTable();
                        }

                        Set<String> installedVersions = dao.getInstalledVersions();

                        for (Entry<String, UpdateService> entry : updateServicesMap.entrySet()) {
                            String version = entry.getKey();

                            UpdateService updateService = entry.getValue();

                            if (!installedVersions.contains(version)) {
                                logger.info(
                                        "Processing update service {} for schema {}.",
                                        version,
                                        schema);

                                con = dao.beginUpdate();

                                updateService.doUpdateScopedBySchema(con);

                                dao.commitUpdate(version, con);

                                updateService.afterUpdate();
                            } else {
                                logger.info(
                                        "Skipping update service {} for schema {}.",
                                        version,
                                        schema);
                            }
                        }

                        return true;
                    } catch (Exception e) {
                        dao.rollbackUpdate(con);
                        e.printStackTrace();
                    }

                    return false;
                });
    }

    @Autowired
    public void setUpdateServicesMap(Map<String, UpdateService> updateServiceMap) {
        this.updateServicesMap = updateServiceMap;
    }
}
