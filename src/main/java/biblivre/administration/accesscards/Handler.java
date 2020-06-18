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
package biblivre.administration.accesscards;

import java.util.LinkedList;

import org.apache.commons.lang3.StringUtils;
import org.json.JSONException;
import org.json.JSONObject;

import biblivre.core.AbstractHandler;
import biblivre.core.BiblivreInitializer;
import biblivre.core.DTOCollection;
import biblivre.core.ExtendedRequest;
import biblivre.core.ExtendedResponse;
import biblivre.core.configurations.Configurations;
import biblivre.core.enums.ActionResult;
import biblivre.core.utils.Constants;

public class Handler extends AbstractHandler {
	private AccessCardBO accessCardBO;

	public Handler() {
		accessCardBO = BiblivreInitializer.getAccessCardBO();
	}

	public void search(ExtendedRequest request, ExtendedResponse response) {
		DTOCollection<AccessCardDTO> list = this.searchHelper(request, response, this);

		try {
			this.json.put("search", list.toJSONObject());
		} catch (JSONException e) {
			this.setMessage(ActionResult.WARNING, "error.invalid_json");
		}
	}

	public DTOCollection<AccessCardDTO> searchHelper(ExtendedRequest request, ExtendedResponse response, AbstractHandler handler) {
		String schema = request.getSchema();
		String searchParameters = request.getString("search_parameters");

		String query = null;
		AccessCardStatus status = null;
		try {
			JSONObject json = new JSONObject(searchParameters);
			query = json.optString("query");
			status = AccessCardStatus.fromString(json.optString("status"));
		} catch (JSONException je) {
			this.setMessage(ActionResult.WARNING, "error.invalid_parameters");
			return null;
		}

		Integer limit = request.getInteger("limit", Configurations.getInt(schema, Constants.CONFIG_SEARCH_RESULTS_PER_PAGE));
		Integer offset = (request.getInteger("page", 1) - 1) * limit;

		DTOCollection<AccessCardDTO> list = accessCardBO.search(query, status, limit, offset);

		if (list.size() == 0) {
			this.setMessage(ActionResult.WARNING, "administration.accesscards.error.no_card_found");
		}

		return list;
	}

	public void paginate(ExtendedRequest request, ExtendedResponse response) {
		this.search(request, response);
	}

	public void open(ExtendedRequest request, ExtendedResponse response) {
		Integer id = request.getInteger("id");

		AccessCardDTO card = accessCardBO.get(id);

		if (card == null) {
			this.setMessage(ActionResult.WARNING, "administration.accesscards.error.card_not_found");
			return;
		}

		try {
			this.json.put("card", card.toJSONObject());
		} catch (JSONException e) {
			this.setMessage(ActionResult.WARNING, "error.invalid_json");
		}
	}

	public void save(ExtendedRequest request, ExtendedResponse response) {
		AccessCardStatus status = request.getEnum(AccessCardStatus.class, "status", AccessCardStatus.AVAILABLE);
		String code = request.getString("code");
		String prefix = request.getString("prefix");
		int start = request.getInteger("start");
		int end = request.getInteger("end");
		String suffix = request.getString("suffix");

		boolean success = false;
		AccessCardDTO returnDto = null;

		if (StringUtils.isNotBlank(code)) {
			returnDto = accessCardBO.createCard(request.getLoggedUserId(), code, status);
		} else {
			LinkedList<AccessCardDTO> list = accessCardBO.saveCardList(prefix, suffix, start, end, request.getLoggedUserId(), status);
			if (list != null) {
				returnDto = list.get(0);
				success = true;
			} else {
				success = false;
			}
		}

		if (success) {
			this.json.put("data", returnDto.toJSONObject());
			this.json.put("full_data", true);

			this.setMessage(ActionResult.SUCCESS, "administration.accesscards.success.save");
		} else {
			this.setMessage(ActionResult.WARNING, "administration.accesscards.error.save");
		}
	}

	public void delete(ExtendedRequest request, ExtendedResponse response) {
		Integer id = request.getInteger("id");

		AccessCardDTO dto = new AccessCardDTO();
		dto.setId(id);
		dto.setModifiedBy(request.getLoggedUserId());
		if (accessCardBO.removeCard(dto)) {
			this.setMessage(ActionResult.SUCCESS, "administration.accesscards.success.delete");
		} else {
			this.setMessage(ActionResult.WARNING, "administration.accesscards.error.delete");
		}
	}

	public void changeStatus(ExtendedRequest request, ExtendedResponse response) {
		Integer id = request.getInteger("id");
		AccessCardStatus status = request.getEnum(AccessCardStatus.class, "status");

		AccessCardDTO dto = accessCardBO.get(id);
		dto.setModifiedBy(request.getLoggedUserId());
		dto.setStatus(status);
		if (accessCardBO.update(dto)) {
			if (status == AccessCardStatus.BLOCKED || status == AccessCardStatus.IN_USE_AND_BLOCKED) {
				this.setMessage(ActionResult.SUCCESS, "administration.accesscards.success.block");
			} else {
				this.setMessage(ActionResult.SUCCESS, "administration.accesscards.success.unblock");
			}
		} else {
			if (status == AccessCardStatus.BLOCKED || status == AccessCardStatus.IN_USE_AND_BLOCKED) {
				this.setMessage(ActionResult.WARNING, "administration.accesscards.error.block");
			} else {
				this.setMessage(ActionResult.WARNING, "administration.accesscards.error.unblock");
			}
		}

		try {
			this.json.put("data", dto.toJSONObject());
			this.json.put("full_data", true);
		} catch (JSONException e) {
			this.setMessage(ActionResult.WARNING, "error.invalid_json");
			return;
		}
	}
}
