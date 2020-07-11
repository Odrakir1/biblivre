package biblivre.digitalmedia;

import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Testcontainers;

import biblivre.core.AbstractDAO;
import biblivre.core.file.BiblivreFile;
import biblivre.core.file.MemoryFile;
import biblivre.core.utils.Constants;
import biblivre.digitalmedia.postgres.PostgresLargeObjectDigitalMediaDAO;

@Testcontainers
@TestInstance(Lifecycle.PER_CLASS)
public class DigitalMediaDAOTest extends AbstractContainerDatabaseTest {
	private DigitalMediaDAO dao;

	private PostgreSQLContainer<?> container = new PostgreSQLContainer<>("postgres:11");

	@BeforeAll
	public void setUp() {
		try {
			container.start();

			String createDatabaseSQL =
				_readSQLAsString("sql/createdatabase.sql");

			performQuery(container, createDatabaseSQL);

			String populateDatabaseSQL =
				_readSQLAsString("sql/biblivre4.sql");

			performQuery(container, populateDatabaseSQL);

			dao =
				AbstractDAO.getInstance(__ -> getDataSource(container),
				PostgresLargeObjectDigitalMediaDAO.class,
				Constants.SINGLE_SCHEMA, Constants.DEFAULT_DATABASE_NAME);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@BeforeEach
	public void deleteAll() {
		List<DigitalMediaDTO> list = dao.list();

		for (DigitalMediaDTO digitalMedia : list) {
			dao.delete(digitalMedia.getId());
		}
	}

	private String _readSQLAsString(String path) throws Exception {
		ClassLoader classLoader = this.getClass().getClassLoader();

		URL resource = classLoader.getResource(path);

		return new String(Files.readAllBytes(Paths.get(resource.toURI())));
	}

	@Test
	public void testCorrectDataIsRetrieved() {
		String fileName = "testfile.txt";

		String fileContent = "foobar";

		MemoryFile file = _createMemoryFile(fileName, fileContent);

		Integer id = dao.save(file);

		BiblivreFile retrievedFile = dao.load(id, fileName);

		assertTrue(fileName.equals(retrievedFile.getName()));

		assertNull(dao.load(0, "nonexistent"));

		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

		try {
			retrievedFile.copy(outputStream);

			assertTrue(fileContent.equals(outputStream.toString()));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void testCorrectBlobIsDeleted() {
		String fileName1 = "testfile1.txt";

		String fileContent1 = "foobar";

		MemoryFile file1 = _createMemoryFile(fileName1, fileContent1);

		String fileName2 = "testfile2.txt";

		String fileContent2 = "foobar";

		MemoryFile file2 = _createMemoryFile(fileName2, fileContent2);

		Integer id1 = dao.save(file1);

		Integer id2 = dao.save(file2);

		dao.delete(id2);

		BiblivreFile retrievedFile1 = dao.load(id1, fileName1);

		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

		try {
			retrievedFile1.copy(outputStream);

			assertTrue(fileContent1.equals(outputStream.toString()));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private MemoryFile _createMemoryFile(String fileName, String content) {
		MemoryFile file = new MemoryFile();

		file.setName(fileName);
		file.setContentType("text/plain");

		ByteArrayInputStream inputStream =
			new ByteArrayInputStream(content.getBytes());

		file.setInputStream(inputStream);

		file.setSize(content.length());
		return file;
	}
}
