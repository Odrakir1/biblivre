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
package biblivre.administration.usertype;

import biblivre.circulation.user.UserBO;
import biblivre.circulation.user.UserDTO;
import biblivre.circulation.user.UserSearchDTO;
import biblivre.core.AbstractBO;
import biblivre.core.AbstractDTO;
import biblivre.core.DTOCollection;
import biblivre.core.exceptions.ValidationException;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class UserTypeBO extends AbstractBO {
    private UserTypeDAO dao;
    private UserBO userBO;

    public UserTypeBO(UserTypeDAO dao, UserBO userBO) {
        super();
        this.dao = dao;
        this.userBO = userBO;
    }

    public static UserTypeBO getInstance() {
        UserTypeBO bo = AbstractBO.getInstance(UserTypeBO.class);
        if (bo.dao == null) {
            bo.dao = UserTypeDAO.getInstance();
        }
        return bo;
    }

    public UserTypeDTO get(int id) {
        return this.dao.get(id);
    }

    public List<UserTypeDTO> list() {
        return this.dao.list();
    }

    public Map<Integer, UserTypeDTO> map() {
        List<UserTypeDTO> list = this.dao.list();
        Map<Integer, UserTypeDTO> map = new TreeMap<>();
        for (UserTypeDTO dto : list) {
            map.put(dto.getId(), dto);
        }
        return map;
    }

    public DTOCollection<UserTypeDTO> search(String value, int limit, int offset) {
        return this.dao.search(value, limit, offset);
    }

    public boolean save(UserTypeDTO userTypeDTO) {
        return this.dao.save(userTypeDTO);
    }

    public boolean delete(int id) {
        // Check if there's any user for this user_type
        UserSearchDTO dto = new UserSearchDTO();
        dto.setType(id);

        DTOCollection<UserDTO> userList = userBO.search(dto, 1, 0);
        boolean existingUser = userList.size() > 0;

        if (existingUser) {
            throw new ValidationException("administration.user_type.error.type_has_users");
        }

        return this.dao.delete(id);
    }

    public boolean saveFromBiblivre3(List<? extends AbstractDTO> dtoList) {
        return this.dao.saveFromBiblivre3(dtoList);
    }

    //	public boolean updateUserType(UserTypeDTO userTypeDTO) {
    //		return dao.update(userTypeDTO);
    //	}

}
