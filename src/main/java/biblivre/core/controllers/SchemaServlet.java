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
package biblivre.core.controllers;

import biblivre.BiblivreInitializer;
import biblivre.administration.backup.BackupBO;
import biblivre.administration.setup.State;
import biblivre.cataloging.Fields;
import biblivre.circulation.user.UserFields;
import biblivre.core.ExtendedRequest;
import biblivre.core.ExtendedResponse;
import biblivre.core.IFCacheableJavascript;
import biblivre.core.SchemaThreadLocal;
import biblivre.core.auth.AuthorizationPoints;
import biblivre.core.configurations.Configurations;
import biblivre.core.file.DiskFile;
import biblivre.core.schemas.SchemasDAOImpl;
import biblivre.core.translations.Translations;
import biblivre.core.utils.Constants;
import biblivre.core.utils.FileIOUtils;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.Writer;
import org.apache.commons.lang3.StringUtils;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

@MultipartConfig
@WebServlet(name = "SchemaServlet", urlPatterns = "/")
public final class SchemaServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Autowired JspController jspController;

    @Autowired DownloadController downloadController;

    @Autowired JsonController jsonController;

    @Override
    protected void doHead(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String path = request.getServletPath();
        boolean isStatic = path.contains("static/") || path.contains("extra/");

        if (isStatic) {
            this.processStaticRequest(request, response, true);
        } else {
            this.processDynamicRequest(request, response, true);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) {
        try {
            BiblivreInitializer.initialize();
            ExtendedRequest xRequest = ((ExtendedRequest) request);

            if (xRequest.mustRedirectToSchema()) {
                String query = xRequest.getQueryString();

                if (StringUtils.isNotBlank(query)) {
                    query = "?" + query;
                } else {
                    query = "";
                }

                ((ExtendedResponse) response).sendRedirect(xRequest.getRequestURI() + "/" + query);
                return;
            }

            String controller = xRequest.getController();

            if (StringUtils.isNotBlank(controller) && controller.equals("status")) {
                Writer out = response.getWriter();
                JSONObject json = new JSONObject();

                SchemaThreadLocal.withSchema(
                        "public",
                        () -> {
                            // TODO: Completar com mais mensagens.
                            // Checking Database
                            SchemaThreadLocal.setSchema("public");

                            if (!SchemasDAOImpl.getInstance().testDatabaseConnection()) {
                                json.put("success", false);
                                json.put("status_message", "Falha no acesso ao Banco de Dados");
                            } else {
                                json.put("success", true);
                                json.put("status_message", "Disponível");
                            }

                            return null;
                        });

                out.write(json.toString());

                return;
            }

            String path = request.getServletPath();
            boolean isStatic = path.contains("static/") || path.contains("extra/");

            if (isStatic) {
                this.processStaticRequest(request, response);
            } else {
                this.processDynamicRequest(request, response);
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        this.processDynamicRequest(request, response);
    }

    protected void processDynamicRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        this.processDynamicRequest(request, response, false);
    }

    protected void processDynamicRequest(
            HttpServletRequest request, HttpServletResponse response, boolean headerOnly)
            throws ServletException, IOException {
        ExtendedRequest xRequest = (ExtendedRequest) request;
        ExtendedResponse xResponse = (ExtendedResponse) response;

        String controller = xRequest.getController();
        String module = xRequest.getString("module");
        String action = xRequest.getString("action");

        AuthorizationPoints notLoggedAtps = AuthorizationPoints.getNotLoggedInstance();
        xRequest.setAttribute("notLoggedAtps", notLoggedAtps);

        // If there is an action but there isn't any controller or module, it's
        // a menu action
        if (StringUtils.isBlank(controller)
                && StringUtils.isBlank(module)
                && StringUtils.isNotBlank(action)) {
            xRequest.setAttribute("module", "menu");
            controller = "jsp";
        } else if (StringUtils.isBlank(controller)
                && (xRequest.getBoolean("force_setup")
                        || Configurations.getBoolean(Constants.CONFIG_NEW_LIBRARY))) {
            xRequest.setAttribute("module", "menu");
            xRequest.setAttribute("action", "setup");
            controller = "jsp";
        }

        if (controller.equals("jsp")) {
            jspController.setHeaderOnly(headerOnly);
            jspController.processRequest();

        } else if (controller.equals("json")) {
            jsonController.setHeaderOnly(headerOnly);
            jsonController.processRequest();

        } else if (controller.equals("download")) {
            downloadController.setHeaderOnly(headerOnly);
            downloadController.processRequest();

        } else if (controller.equals("media") || controller.equals("DigitalMediaController")) {
            xRequest.setAttribute("module", "digitalmedia");
            xRequest.setAttribute("action", "download");

            downloadController.setHeaderOnly(headerOnly);
            downloadController.processRequest();

        } else if (controller.equals("log")) {
            xResponse.setContentType("text/html;charset=UTF-8");
            xRequest.dispatch("/jsp/log.jsp", xResponse);
        } else {
            xResponse.setContentType("text/html;charset=UTF-8");

            String page = "/jsp/index.jsp";

            if (State.LOCKED.get()) {
                page = "/jsp/progress.jsp";
            }

            xRequest.dispatch(page, xResponse);
        }
    }

    protected void processStaticRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        this.processStaticRequest(request, response, false);
    }

    protected void processStaticRequest(
            HttpServletRequest request, HttpServletResponse response, boolean headerOnly)
            throws ServletException, IOException {
        final String path = request.getServletPath();
        final String realPath;

        if (path.contains("static/")) {
            realPath = path.substring(path.lastIndexOf("/static"));
        } else {
            realPath = path.substring(path.lastIndexOf("/extra"));
        }

        if (realPath.endsWith(".i18n.js")
                || realPath.endsWith(".form.js")
                || realPath.endsWith(".user_fields.js")) {
            String filename = StringUtils.substringAfterLast(path, "/");
            String[] params = StringUtils.split(filename, ".");

            String schema = params[0];

            IFCacheableJavascript javascript = null;

            if (realPath.endsWith(".i18n.js")) {
                javascript =
                        SchemaThreadLocal.withSchema(schema, () -> Translations.get(params[1]));
            } else if (realPath.endsWith(".user_fields.js")) {
                javascript = SchemaThreadLocal.withSchema(schema, UserFields::getFields);
            } else {
                javascript =
                        SchemaThreadLocal.withSchema(schema, () -> Fields.getFormFields(params[2]));
            }

            File cacheFile = javascript.getCacheFile();

            if (cacheFile != null) {
                DiskFile diskFile = new DiskFile(cacheFile, "application/javascript;charset=UTF-8");

                FileIOUtils.sendHttpFile(diskFile, request, response, headerOnly);
            } else {
                response.getOutputStream().print(javascript.toJavascriptString());
            }
            return;
        }

        // Other static files
        RequestDispatcher rd = this.getServletContext().getNamedDispatcher("default");

        ExtendedRequest wrapped =
                new ExtendedRequest(request) {

                    @Override
                    public String getServletPath() {
                        return realPath;
                    }
                };

        rd.forward(wrapped, response);
    }

    @Override
    public void init() throws ServletException {
        //
        // FreemarkerTemplateHelper.freemarkerConfiguration.setServletContextForTemplateLoading(
        //                getServletContext(), "/freemarker");
    }

    private static final Logger logger = LoggerFactory.getLogger(BackupBO.class);
}
