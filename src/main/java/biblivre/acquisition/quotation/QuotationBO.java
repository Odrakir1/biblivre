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
package biblivre.acquisition.quotation;

import biblivre.acquisition.request.RequestBO;
import biblivre.acquisition.request.RequestDTO;
import biblivre.acquisition.supplier.SupplierBO;
import biblivre.acquisition.supplier.SupplierDTO;
import biblivre.core.AbstractBO;
import biblivre.core.AbstractDTO;
import biblivre.core.DTOCollection;
import java.util.List;

public class QuotationBO extends AbstractBO {
    private QuotationDAO dao;
    private SupplierBO supplierBO;
    private RequestBO requestBO;

    public QuotationBO(QuotationDAO dao, SupplierBO supplierBO, RequestBO requestBO) {
        super();
        this.dao = dao;
        this.supplierBO = supplierBO;
        this.requestBO = requestBO;
    }

    public QuotationDTO get(Integer id) {
        QuotationDTO dto = this.dao.get(id);

        this.populateDTO(dto, requestBO, supplierBO);

        return dto;
    }

    public Integer save(QuotationDTO dto) {
        return this.dao.save(dto);
    }

    public boolean update(QuotationDTO dto) {
        return this.dao.update(dto);
    }

    public boolean delete(QuotationDTO dto) {
        return this.dao.delete(dto);
    }

    public DTOCollection<QuotationDTO> list() {
        return this.search(null, Integer.MAX_VALUE, 0);
    }

    public DTOCollection<QuotationDTO> search(String value, int limit, int offset) {
        DTOCollection<QuotationDTO> list = this.dao.search(value, limit, offset);

        for (QuotationDTO quotation : list) {
            this.populateDTO(quotation, requestBO, supplierBO);
        }
        return list;
    }

    public DTOCollection<QuotationDTO> list(Integer supplierId) {
        DTOCollection<QuotationDTO> list = this.dao.list(supplierId);

        for (QuotationDTO quotation : list) {
            this.populateDTO(quotation, requestBO, supplierBO);
        }
        return list;
    }

    public List<RequestQuotationDTO> listRequestQuotation(Integer quotationId) {
        return this.dao.listRequestQuotation(quotationId);
    }

    private void populateDTO(QuotationDTO dto, RequestBO rbo, SupplierBO sbo) {
        List<RequestQuotationDTO> rqList = this.dao.listRequestQuotation(dto.getId());
        for (RequestQuotationDTO rqdto : rqList) {
            RequestDTO request = rbo.get(rqdto.getRequestId());
            rqdto.setAuthor(request.getAuthor());
            rqdto.setTitle(request.getTitle());
        }
        dto.setQuotationsList(rqList);

        SupplierDTO sdto = sbo.get(dto.getSupplierId());
        dto.setSupplierName(sdto.getTrademark());
    }

    public boolean saveFromBiblivre3(List<? extends AbstractDTO> dtoList) {
        return this.dao.saveFromBiblivre3(dtoList);
    }
}
