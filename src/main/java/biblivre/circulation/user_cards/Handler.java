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
package biblivre.circulation.user_cards;

import biblivre.circulation.user.UserBO;
import biblivre.core.AbstractHandler;
import biblivre.core.ExtendedRequest;
import biblivre.core.ExtendedResponse;
import biblivre.core.LabelPrintDTO;
import biblivre.core.enums.ActionResult;
import biblivre.core.file.DiskFile;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.json.JSONException;

public class Handler extends AbstractHandler {

    private UserBO userBO;

	public Handler(UserBO userBO) {
		super();
		this.userBO = userBO;
	}

	public void createPdf(ExtendedRequest request, ExtendedResponse response) {
        LabelPrintDTO print = getLabelPrintDTO(request);

        if (print == null) {
            this.setMessage(ActionResult.WARNING, "error.invalid_parameters");
            return;
        }

        String printId = UUID.randomUUID().toString();
        String schema = request.getSchema();

        request.setSessionAttribute(schema, printId, print);

        try {
            this.json.put("uuid", printId);
        } catch (JSONException e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
        }
    }

    public void downloadPdf(ExtendedRequest request, ExtendedResponse response) {
        String schema = request.getSchema();
        String printId = request.getString("id");
        LabelPrintDTO dto = (LabelPrintDTO) request.getSessionAttribute(schema, printId);
        final DiskFile exportFile = userBO.printUserCardsToPDF(dto, request.getTranslationsMap());

        userBO.markAsPrinted(dto.getIds());

        this.setFile(exportFile);

        this.setCallback(exportFile::delete);
    }

    private LabelPrintDTO getLabelPrintDTO(ExtendedRequest request) {
        LabelPrintDTO print = new LabelPrintDTO();

        try {
            String idList = request.getString("id_list");
            String[] idArray = idList.split(",");
            Set<Integer> ids = new HashSet<>();
            for (int i = 0; i < idArray.length; i++) {
                ids.add(Integer.valueOf(idArray[i]));
            }
            print.setIds(ids);
            print.setOffset(request.getInteger("offset"));
            print.setWidth(request.getFloat("width"));
            print.setHeight(request.getFloat("height"));
            print.setColumns(request.getInteger("columns"));
            print.setRows(request.getInteger("rows"));

            return print;
        } catch (NumberFormatException nfe) {
            return null;
        }
    }
}
