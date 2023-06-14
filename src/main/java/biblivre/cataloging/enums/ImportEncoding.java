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
package biblivre.cataloging.enums;

import biblivre.core.file.MemoryFile;
import biblivre.core.utils.BiblivreEnum;
import biblivre.core.utils.TextUtils;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import org.apache.commons.lang3.StringUtils;

public enum ImportEncoding implements BiblivreEnum {
    AUTO_DETECT,
    UTF8,
    MARC8;

    public static ImportEncoding fromString(String str) {
        if (StringUtils.isBlank(str)) {
            return null;
        }

        str = str.toLowerCase();

        for (ImportEncoding importEncoding : ImportEncoding.values()) {
            if (str.equals(importEncoding.name().toLowerCase())) {
                return importEncoding;
            }
        }

        return null;
    }

    @Override
    public String toString() {
        return this.name().toLowerCase();
    }

    public String getString() {
        return this.toString();
    }

    public String getEncoding(MemoryFile file) throws IOException {
        switch (this) {
            case AUTO_DETECT -> {
                try (InputStream is = file.getInputStream()) {
                    return TextUtils.detectCharset(is);
                }
            }
            case UTF8 -> {
                return StandardCharsets.UTF_8.name();
            }
            case MARC8 -> {
                return StandardCharsets.ISO_8859_1.name();
            }
        }

        return null;
    }
}
