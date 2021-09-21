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
package biblivre.core;

import biblivre.core.auth.AuthorizationPoints;
import biblivre.core.configurations.Configurations;
import biblivre.core.file.MemoryFile;
import biblivre.core.schemas.Schemas;
import biblivre.core.translations.Languages;
import biblivre.core.translations.Translations;
import biblivre.core.translations.TranslationsMap;
import biblivre.core.utils.Constants;
import biblivre.login.LoginDTO;
import java.io.IOException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpSession;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileItemFactory;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.lang3.StringUtils;

public class ExtendedRequest extends HttpServletRequestWrapper {
    private TranslationsMap translationsMap;

    private String controller;
    private String language;
    private boolean mustRedirectToSchema;
    private boolean multiPart;
    private Map<String, String> multiPartParameters;
    private Map<String, MemoryFile> multiPartFiles;

    public ExtendedRequest(HttpServletRequest request) {
        super(request);

        String path = request.getServletPath();

        if (path.contains("static/")) {
            return;
        }

        this.loadMultiPart();
        this.loadSchemaAndController();
        this.loadLanguage();
        this.loadTranslationsMap();
    }

    public String getLocalizedText(String key) {
        String[] params = key.split(":::");

        if (params.length == 1) {
            return this.translationsMap.getText(key);
        }

        String text = this.translationsMap.getText(params[0]);
        for (int i = 1; i < params.length; i++) {
            String replacement = params[i];
            text = text.replace("{" + (i - 1) + "}", replacement);
        }
        return text;
    }

    public void dispatch(String url, ExtendedResponse response)
            throws ServletException, IOException {
        this.getRequestDispatcher(url).forward(this, response);
    }

    public void setScopedSessionAttribute(String key, Object obj) {
        String schema = SchemaThreadLocal.get();

        setSessionAttribute(schema + "." + key, obj);
    }

    public void setSessionAttribute(String key, Object obj) {
        this.getSession().setAttribute(key, obj);
    }

    public Object getSessionAttribute(String key) {
        return this.getSession().getAttribute(key);
    }

    public Object getScopedSessionAttribute(String key) {
        String schema = SchemaThreadLocal.get();

        return this.getSessionAttribute(schema + "." + key);
    }

    public boolean hasParameter(String key) {
        return this.getParameterMap().containsKey(key);
    }

    public String getString(String key) {
        if (!key.equals("action") && !key.equals("controller")) {
            // Translations.addSingleTranslation(this.schema, this.language, "audit." +
            // this.controller + "." + this.getString("action") + "." + key, key);
        }

        return this.getString(key, "");
    }

    public String getString(String key, String defaultValue) {
        String value = this.getRequestParameter(key);

        return StringUtils.defaultString(value, defaultValue);
    }

    public Integer getInteger(String key) {
        return this.getInteger(key, 0);
    }

    public Integer getInteger(String key, Integer defaultValue) {
        Integer retValue = defaultValue;

        try {
            retValue = Integer.valueOf(this.getRequestParameter(key));
        } catch (NumberFormatException e) {
        }

        return retValue;
    }

    public Float getFloat(String key) {
        return this.getFloat(key, 0.0f);
    }

    public Float getFloat(String key, Float defaultValue) {
        Float retValue = defaultValue;

        try {
            retValue = Float.valueOf(this.getRequestParameter(key));
        } catch (NumberFormatException e) {
        }

        return retValue;
    }

    public boolean getBoolean(String key) {
        return this.getBoolean(key, false);
    }

    public boolean getBoolean(String key, boolean defaultValue) {
        String value = this.getRequestParameter(key);

        if (StringUtils.isBlank(value)) {
            return defaultValue;
        } else if (value.toLowerCase().equals("true")) {
            return true;
        } else if (value.toLowerCase().equals("false")) {
            return false;
        }

        return defaultValue;
    }

    public <T extends Enum<T>> T getEnum(Class<T> type, String key) {
        return this.getEnum(type, key, null);
    }

    public <T extends Enum<T>> T getEnum(Class<T> type, String key, T defaultValue) {
        String value = this.getString(key);

        if (StringUtils.isBlank(value)) {
            return defaultValue;
        }

        try {
            return Enum.valueOf(type, value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return defaultValue;
        }
    }

    public MemoryFile getFile(String key) {
        return this.multiPart ? this.multiPartFiles.get(key) : null;
    }

    public String getRequestParameter(String key) {
        return this.multiPart ? this.multiPartParameters.get(key) : super.getParameter(key);
    }

    public void setController(String controller) {
        this.controller = controller;
    }

    public String getController() {
        return StringUtils.defaultString(this.controller);
    }

    public void setLanguage(String language) {
        this.language = language;
        this.setAttribute("language", language);
    }

    public String getLanguage() {
        return this.language;
    }

    public Locale getSelectedLocale() {
        Locale locale = Translations.toLocale(this.getLanguage());

        return (locale == null) ? this.getLocale() : locale;
    }

    public void setMustRedirectToSchema(boolean mustRedirectToSchema) {
        this.mustRedirectToSchema = mustRedirectToSchema;
    }

    public boolean mustRedirectToSchema() {
        return this.mustRedirectToSchema;
    }

    public void setTranslationsMap(TranslationsMap translationsMap) {
        this.translationsMap = translationsMap;
        this.setAttribute("translationsMap", translationsMap);
    }

    public TranslationsMap getTranslationsMap() {
        return this.translationsMap;
    }

    public boolean isMultiPart() {
        return this.multiPart;
    }

    public int getLoggedUserId() {
        Object user = this.getScopedSessionAttribute("logged_user");

        if (user != null && user instanceof LoginDTO) {
            return ((LoginDTO) user).getId();
        }

        return 0;
    }

    private void loadMultiPart() {
        this.multiPart = ServletFileUpload.isMultipartContent(this);

        if (this.multiPart) {
            this.multiPartParameters = new HashMap<>();
            this.multiPartFiles = new HashMap<>();

            try {
                FileItemFactory factory = new DiskFileItemFactory();
                ServletFileUpload upload = new ServletFileUpload(factory);
                List<FileItem> items = upload.parseRequest(this);

                for (FileItem item : items) {
                    if (item.isFormField()) {
                        this.multiPartParameters.put(item.getFieldName(), item.getString());
                    } else {
                        MemoryFile file = new MemoryFile(item);

                        this.multiPartFiles.put(item.getFieldName(), file);
                    }
                }
            } catch (Exception e) {
                // TODO: handle exception
            }
        }
    }

    private void loadSchemaAndController() {
        String url = this.getRequestURI().substring(this.getContextPath().length() + 1);
        String schema = null;
        String controller = null;

        if (StringUtils.isNotBlank(url)) {
            String[] urlArray = url.split("/");

            schema = urlArray[0];

            if (schema.equals("DigitalMediaController")) {
                schema = null;
                controller = "DigitalMediaController";
            }

            if (urlArray.length > 1) {
                controller = urlArray[1];
            } else if (!url.endsWith("/")) {
                this.setMustRedirectToSchema(true);
            }
        }

        if (Schemas.isNotLoaded(schema)) {
            boolean isMultipleSchemasEnabled = Schemas.isMultipleSchemasEnabled();

            if (isMultipleSchemasEnabled) {
                schema = Constants.GLOBAL_SCHEMA;
            } else {
                schema = Constants.SINGLE_SCHEMA;
            }
        }

        if (controller == null) {
            controller = this.getString("controller");
        }

        SchemaThreadLocal.setSchema(schema);

        this.setController(controller);
    }

    public void clearSessionAttributes(String schema) {
        Enumeration<String> atributes = this.getSession().getAttributeNames();
        while (atributes.hasMoreElements()) {
            String attribute = atributes.nextElement();
            if (StringUtils.defaultString(attribute).startsWith("schema.")) {
                this.getSession().removeAttribute(attribute);
            }
        }
    }

    private void loadLanguage() {
        HttpSession session = this.getSession();

        String language = this.getString("i18n");

        String schema = SchemaThreadLocal.get();

        if (Languages.isNotLoaded(language)) {
            language = (String) session.getAttribute(schema + ".language");
        }

        if (Languages.isNotLoaded(language)) {
            language = (String) session.getAttribute("global.language");
        }

        if (Languages.isNotLoaded(language)) {
            language = this.getLocale().toString().replaceAll("[_]", "-");
        }

        if (Languages.isNotLoaded(language)) {
            language = Configurations.getString(Constants.CONFIG_DEFAULT_LANGUAGE);
        }

        if (Languages.isNotLoaded(language)) {
            language = "pt-BR";
        }

        if (Languages.isNotLoaded(language)) {
            language = Languages.getDefaultLanguage();
        }

        this.setScopedSessionAttribute("language", language);

        this.setLanguage(language);
    }

    private void loadTranslationsMap() {
        this.setTranslationsMap(Translations.get(this.language));
    }

    @Deprecated
    @Override
    public String getParameter(String name) {
        return super.getParameter(name);
    }

    public AuthorizationPoints getAuthorizationPoints() {
        return (AuthorizationPoints) getScopedSessionAttribute("logged_user_atps");
    }
}
