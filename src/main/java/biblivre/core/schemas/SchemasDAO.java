package biblivre.core.schemas;

import java.util.Set;

public interface SchemasDAO {

	Set<SchemaDTO> list();

	boolean insert(SchemaDTO dto);

	boolean delete(SchemaDTO dto);

	boolean save(SchemaDTO dto);

	boolean exists(String schema);

}