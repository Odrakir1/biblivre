package biblivre.acquisition.request;

import java.util.List;

import biblivre.core.AbstractDTO;
import biblivre.core.DTOCollection;

public interface RequestDAO {

	boolean save(RequestDTO dto);

	boolean saveFromBiblivre3(List<? extends AbstractDTO> dtoList);

	RequestDTO get(int id);

	DTOCollection<RequestDTO> search(String value, int limit, int offset);

	boolean update(RequestDTO dto);

	boolean updateRequestStatus(int orderId, RequestStatus status);

	boolean delete(RequestDTO dto);

}