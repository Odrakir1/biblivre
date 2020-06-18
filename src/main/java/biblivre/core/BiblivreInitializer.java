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

import biblivre.acquisition.order.OrderBO;
import biblivre.acquisition.order.OrderDAO;
import biblivre.acquisition.quotation.QuotationBO;
import biblivre.acquisition.quotation.QuotationDAO;
import biblivre.acquisition.request.RequestBO;
import biblivre.acquisition.request.RequestDAO;
import biblivre.acquisition.supplier.SupplierBO;
import biblivre.acquisition.supplier.SupplierDAO;
import biblivre.administration.accesscards.AccessCardBO;
import biblivre.administration.accesscards.AccessCardDAO;
import biblivre.circulation.accesscontrol.AccessControlBO;
import biblivre.circulation.accesscontrol.AccessControlDAO;
import biblivre.z3950.server.Z3950ServerBO;

public class BiblivreInitializer {
	private static SupplierBO supplierBO;
	private static QuotationBO quotationBO;
	private static RequestBO requestBO;
	private static OrderBO orderBO;
	private static AccessCardBO accessCardBO;
	private static AccessControlBO accessControlBO;

	private static boolean initialized = false;
	public static Z3950ServerBO Z3950server = null;


	public synchronized static void initialize() {
		if (!BiblivreInitializer.initialized) {
			try {
				Updates.fixPostgreSQL81();
				Updates.globalUpdate();

				BiblivreInitializer.Z3950server = new Z3950ServerBO();
				BiblivreInitializer.Z3950server.startServer();

				BiblivreInitializer.initialized = true;
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	public synchronized static void destroy() {
		if (BiblivreInitializer.Z3950server != null) {
			BiblivreInitializer.Z3950server.stopServer();
		}
	}

	public synchronized static void reloadZ3950Server() {
		if (BiblivreInitializer.Z3950server != null) {
			BiblivreInitializer.Z3950server.reloadServer();
		}
	}

	public static SupplierBO getSupplierBO() {
		if (supplierBO == null) {
			supplierBO = new SupplierBO(
				AbstractDAO.getInstance(SupplierDAO.class));
		}

		return supplierBO;
	}

	public static QuotationBO getQuotationBO() {
		if (quotationBO == null) {
			quotationBO = new QuotationBO(
				AbstractDAO.getInstance(QuotationDAO.class),
				getSupplierBO(), getRequestBO());
		}

		return quotationBO;
	}

	public static RequestBO getRequestBO() {
		if (requestBO == null) {
			requestBO = new RequestBO(
				AbstractDAO.getInstance(RequestDAO.class));
		}

		return requestBO;
	}

	public static OrderBO getOrderBO() {
		if (orderBO == null) {
			orderBO = new OrderBO(
				AbstractDAO.getInstance(OrderDAO.class), getSupplierBO(),
				getQuotationBO(), getRequestBO());
		}

		return orderBO;
	}

	public static AccessCardBO getAccessCardBO() {
		if (accessCardBO == null) {
			accessCardBO = new AccessCardBO(
				AbstractDAO.getInstance(AccessCardDAO.class));
		}

		return accessCardBO;
	}

	public static AccessControlBO getAccessControlBO() {
		if (accessControlBO == null) {
			accessControlBO = new AccessControlBO(
				AbstractDAO.getInstance(AccessControlDAO.class),
				getAccessCardBO());
		}

		return accessControlBO;
	}
}
