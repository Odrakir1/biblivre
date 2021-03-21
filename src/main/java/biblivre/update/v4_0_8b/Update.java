package biblivre.update.v4_0_8b;

import biblivre.core.translations.Translations;
import biblivre.update.UpdateService;
import java.sql.Connection;

public class Update implements UpdateService {

    @Override
    public void doUpdate(Connection connection) {
        Translations.addSingleTranslation(
                "pt-BR",
                "administration.setup.biblivre3restore.log_header",
                "[Log de restauração de backup do Biblivre 3]\n\n");

        Translations.addSingleTranslation(
                "en-US",
                "administration.setup.biblivre3restore.log_header",
                "[Log for Biblivre 3 backup restoration]\n\n");

        Translations.addSingleTranslation(
                "es",
                "administration.setup.biblivre3restore.log_header",
                "[Log de restauración de backup del Biblivre 3]\n\n");
    }

    @Override
    public String getVersion() {
        return "4.0.8b";
    }
}
