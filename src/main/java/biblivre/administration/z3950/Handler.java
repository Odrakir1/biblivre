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
package biblivre.administration.z3950;

import biblivre.core.AbstractHandler;
import biblivre.core.DTOCollection;
import biblivre.core.ExtendedRequest;
import biblivre.core.ExtendedResponse;
import biblivre.core.configurations.Configurations;
import biblivre.core.enums.ActionResult;
import biblivre.core.utils.Constants;
import biblivre.z3950.Z3950AddressDTO;
import biblivre.z3950.Z3950BO;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("biblivre.administration.z3950.Handler")
public class Handler extends AbstractHandler {
    private Z3950BO z3950BO;

    public void search(ExtendedRequest request, ExtendedResponse response) {

        String searchParameters = request.getString("search_parameters");

        String query = null;

        try {
            JSONObject json = new JSONObject(searchParameters);
            query = json.optString("query");
        } catch (JSONException je) {
            this.setMessage(ActionResult.WARNING, "error.invalid_parameters");
            return;
        }

        Integer limit =
                request.getInteger(
                        "limit", Configurations.getInt(Constants.CONFIG_SEARCH_RESULTS_PER_PAGE));
        Integer offset = (request.getInteger("page", 1) - 1) * limit;

        DTOCollection<Z3950AddressDTO> list = z3950BO.search(query, limit, offset);

        if (list.size() == 0) {
            this.setMessage(ActionResult.WARNING, "administration.z3950.no_server_found");
            return;
        }

        try {
            this.json.put("search", list.toJSONObject());
        } catch (JSONException e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
            return;
        }
    }

    public void paginate(ExtendedRequest request, ExtendedResponse response) {
        this.search(request, response);
    }

    public void save(ExtendedRequest request, ExtendedResponse response) {
        Z3950AddressDTO dto = new Z3950AddressDTO();
        Integer id = request.getInteger("id");
        if (id != null && id != 0) {
            dto.setId(id);
        }
        dto.setName(request.getString("name"));
        dto.setUrl(request.getString("url"));
        dto.setPort(request.getInteger("port"));
        dto.setCollection(request.getString("collection"));

        if (z3950BO.save(dto)) {
            if (id == 0) {
                this.setMessage(ActionResult.SUCCESS, "administration.z3950.success.save");
            } else {
                this.setMessage(ActionResult.SUCCESS, "administration.z3950.success.update");
            }
        } else {
            this.setMessage(ActionResult.WARNING, "administration.z3950.error.save");
        }

        try {
            this.json.put("data", dto.toJSONObject());
            this.json.put("full_data", true);
        } catch (JSONException e) {
            this.setMessage(ActionResult.WARNING, "error.invalid_json");
            return;
        }
    }

    public void delete(ExtendedRequest request, ExtendedResponse response) {
        Z3950AddressDTO dto = new Z3950AddressDTO();
        dto.setId(request.getInteger("id"));

        if (z3950BO.delete(dto)) {
            this.setMessage(ActionResult.SUCCESS, "administration.z3950.success.delete");
        } else {
            this.setMessage(ActionResult.ERROR, "administration.z3950.error.delete");
        }
    }

    @Autowired
    public void setZ3950BO(Z3950BO z3950bo) {
        z3950BO = z3950bo;
    }
}
