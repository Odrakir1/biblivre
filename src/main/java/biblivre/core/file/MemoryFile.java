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
package biblivre.core.file;

import biblivre.core.utils.Constants;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import org.apache.commons.io.IOUtils;

public class MemoryFile extends BiblivreFile {

    private InputStream inputStream;

    public MemoryFile() {}

    public InputStream getNewInputStream() throws IOException {
        return this.inputStream;
    }

    public void setInputStream(InputStream is) {
        this.inputStream = is;
    }

    public InputStream getInputStream() throws IOException {
        if (this.inputStream == null) {
            return this.getNewInputStream();
        }

        return this.inputStream;
    }

    @Override
    public boolean exists() {
        try {
            InputStream inputStream = this.getNewInputStream();

            return inputStream != null;
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public void copy(OutputStream out, long start, long size) throws IOException {
        InputStream input = this.getNewInputStream();

        if (input == null) {
            return;
        }

        if (start != 0) {
            throw new IOException("MemoryFile doesn't implements seek. Start parameter must be 0");
        }

        byte[] buffer = new byte[Constants.DEFAULT_BUFFER_SIZE];
        int read;

        while ((read = input.read(buffer)) > 0) {
            out.write(buffer, 0, read);
        }

        IOUtils.closeQuietly(input);
    }

    @Override
    public void close() {
        IOUtils.closeQuietly(this.inputStream);
    }
}
