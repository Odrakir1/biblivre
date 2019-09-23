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
package biblivre.administration.reports;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

import javax.naming.InitialContext;
import javax.sql.DataSource;

import org.apache.commons.lang3.StringUtils;
import org.marc4j.marc.Record;

import biblivre.administration.reports.dto.AllUsersReportDto;
import biblivre.administration.reports.dto.AssetHoldingByDateDto;
import biblivre.administration.reports.dto.AssetHoldingDto;
import biblivre.administration.reports.dto.BibliographyReportDto;
import biblivre.administration.reports.dto.DeweyReportDto;
import biblivre.administration.reports.dto.HoldingCreationByDateReportDto;
import biblivre.administration.reports.dto.LateLendingsDto;
import biblivre.administration.reports.dto.LendingsByDateReportDto;
import biblivre.administration.reports.dto.RequestsByDateReportDto;
import biblivre.administration.reports.dto.ReservationReportDto;
import biblivre.administration.reports.dto.SearchesByDateReportDto;
import biblivre.administration.reports.dto.SummaryReportDto;
import biblivre.cataloging.RecordDTO;
import biblivre.cataloging.bibliographic.BiblioRecordBO;
import biblivre.cataloging.enums.RecordDatabase;
import biblivre.circulation.user.UserStatus;
import biblivre.core.exceptions.DAOException;
import biblivre.core.utils.Constants;
import biblivre.core.utils.TextUtils;
import biblivre.marc.MarcDataReader;
import biblivre.marc.MarcUtils;

public class ReportsDAOImpl implements ReportsDAO {

	private String schema;

	private String dataSourceName;

	public ReportsDAOImpl(String dataSourceName, String schema) {
		this.schema = schema;
		this.dataSourceName = dataSourceName;
	}

	public String getSchema() {
		return this.schema;
	}

	public SummaryReportDto getSummaryReportData(RecordDatabase database) {
		SummaryReportDto dto = new SummaryReportDto();

		String sql = "SELECT r.iso2709, count(h.id) as holding_count FROM single.biblio_records r inner join single.biblio_holdings h on r.id = h.record_id where r.database = ? group by r.iso2709;";

		try (Connection con = this.getConnection();
				PreparedStatement pst = _createPreparedStatementWith100Rows(sql, con)) {

			pst.setString(1, database.toString());

			try (ResultSet rs = pst.executeQuery()) {

				List<String[]> dataList = new ArrayList<String[]>();

				while (rs.next()) {
					Record record = MarcUtils.iso2709ToRecord(rs.getBytes("iso2709"));

					MarcDataReader dataReader = new MarcDataReader(record);

					String[] data = new String[8];

					String title = dataReader.getTitle(false);

					data[0] = StringUtils.isNotBlank(title) ? title : "";

					String author = dataReader.getAuthor(true);

					data[1] = StringUtils.isNotBlank(author) ? author : "";

					String isbn = dataReader.getIsbn();

					data[2] = StringUtils.isNotBlank(isbn) ? isbn : "";

					String editor = dataReader.getEditor();

					data[3] = StringUtils.isNotBlank(editor) ? editor : "";// editora(50)

					String year = dataReader.getPublicationYear();

					data[4] = StringUtils.isNotBlank(year) ? year : "";// ano(20)

					String edition = dataReader.getEdition();

					data[5] = StringUtils.isNotBlank(edition) ? edition : "";

					String dewey = dataReader.getDDCN();

					data[6] = StringUtils.isNotBlank(dewey) ? dewey : "";

					data[7] = rs.getString("holding_count");

					dataList.add(data);
				}

				dto.setData(dataList);
			}

			return dto;
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public DeweyReportDto getDeweyReportData(RecordDatabase db, String datafield, int digits) {
		DeweyReportDto dto = new DeweyReportDto();

		StringBuilder sql = new StringBuilder();
		sql.append("SELECT b.iso2709, count(h.id) as holdings FROM biblio_records b ");
		sql.append("LEFT OUTER JOIN biblio_holdings h ");
		sql.append("ON b.id = h.record_id ");
		sql.append("WHERE b.database = ? ");
		sql.append("GROUP BY b.iso2709; ");

		try (Connection con = this.getConnection();
				PreparedStatement pst = con.prepareStatement(sql.toString())) {

			pst.setString(1, db.toString());

			try (ResultSet rs = pst.executeQuery()) {

				Map<String, Integer[]> acc = new HashMap<String, Integer[]>();

				while (rs.next()) {
					Record record = MarcUtils.iso2709ToRecord(rs.getString("iso2709"));

					String dewey = "";

					MarcDataReader dataReader = new MarcDataReader(record);

					if (datafield.equals("082")) {
						dewey = dataReader.getDDCN();
					} else if (datafield.equals("090")) {
						dewey = dataReader.getLocation();
					}

					String formattedDewey = ReportUtils.formatDeweyString(dewey, digits);

					Integer numberOfHoldings = rs.getInt("holdings");

					Integer[] totals = acc.get(formattedDewey);

					if (totals == null) {
						acc.put(formattedDewey, new Integer[] { 1, numberOfHoldings });
					} else {
						Integer[] newTotals = new Integer[] { totals[0] + 1, totals[1] + numberOfHoldings };
						acc.put(formattedDewey, newTotals);
					}
				}

				List<String[]> data = new ArrayList<String[]>();

				dto.setData(data);

				for (String key : acc.keySet()) {
					String[] arrayData = new String[3];

					arrayData[0] = key;

					Integer[] totals = acc.get(key);

					arrayData[1] = String.valueOf(totals[0]);

					arrayData[2] = String.valueOf(totals[1]);

					dto.getData().add(arrayData);
				}

				return dto;
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public AssetHoldingDto getAssetHoldingReportData() {
		AssetHoldingDto dto = new AssetHoldingDto();

		StringBuilder sql = new StringBuilder();

		sql.append(" SELECT H.accession_number, R.iso2709 FROM biblio_holdings H INNER JOIN biblio_records R ");
		sql.append(" ON R.id = H.record_id WHERE H.database = 'main' ");
		sql.append(" ORDER BY H.accession_number ");

		try (Connection con = this.getConnection();
				PreparedStatement pst = _createPreparedStatementWith100Rows(sql.toString(), con);
				ResultSet rs = pst.executeQuery();
				) {

			List<String[]> dataList = new ArrayList<String[]>();

			while (rs.next()) {
				Record record = MarcUtils.iso2709ToRecord(rs.getBytes("iso2709"));

				MarcDataReader dataReader = new MarcDataReader(record);

				String assetHolding = rs.getString("accession_number");

				String[] data = new String[5];

				data[0] = assetHolding;

				data[1] = dataReader.getAuthorName(false);

				data[2] = dataReader.getTitle(false);

				data[3] = dataReader.getEdition();

				data[4] = dataReader.getPublicationYear();

				dataList.add(data);
			}
			dto.setData(dataList);
		} catch (Exception e) {
			throw new DAOException(e);
		}

		return dto;
	}

	public AssetHoldingDto getAssetHoldingFullReportData() {
		AssetHoldingDto dto = new AssetHoldingDto();
		Connection con = null;
		try {
			con = this.getConnection();
			StringBuilder sql = new StringBuilder();
			sql.append(" SELECT H.id, H.accession_number, R.iso2709 FROM biblio_holdings H INNER JOIN biblio_records R ");
			sql.append(" ON R.id = H.record_id WHERE H.database = 'main' ");
			sql.append(" ORDER BY H.accession_number ");

			final PreparedStatement pst = con.prepareStatement(sql.toString());
			pst.setFetchSize(100);

			final ResultSet rs = pst.executeQuery();
			List<String[]> dataList = new ArrayList<String[]>();
			while (rs.next()) {
				Record record = MarcUtils.iso2709ToRecord(rs.getBytes("iso2709"));
				MarcDataReader dataReader = new MarcDataReader(record);
				String assetHolding = rs.getString("accession_number");
				String serial = rs.getString("id");
				String[] data = new String[7];
				data[0] = serial;
				data[1] = assetHolding;
				data[2] = dataReader.getTitle(false);
				data[3] = dataReader.getAuthorName(false);
				String location = dataReader.getShelfLocation();
				data[4] = StringUtils.isNotBlank(location) ? location : "";
				data[5] = dataReader.getEdition();
				data[6] = dataReader.getPublicationYear();
				dataList.add(data);
			}
			dto.setData(dataList);
		} catch (Exception e) {
			throw new DAOException(e);
		}

		return dto;
	}

	public AssetHoldingByDateDto getAssetHoldingByDateReportData(String initialDate, String finalDate) {
		AssetHoldingByDateDto dto = new AssetHoldingByDateDto();
		Connection con = null;
		try {
			con = this.getConnection();
			StringBuilder sql = new StringBuilder();
			sql.append(" SELECT H.accession_number, to_char(H.created, 'DD/MM/YYYY'), R.iso2709, H.iso2709 ");
			sql.append(" FROM biblio_holdings H INNER JOIN biblio_records R ");
			sql.append(" ON R.id = H.record_id WHERE H.database = 'main' ");
			sql.append(" AND H.created >= to_date(?, 'DD-MM-YYYY') ");
			sql.append(" AND H.created <= to_date(?, 'DD-MM-YYYY') ");
			sql.append(" ORDER BY H.created, H.accession_number ");

			final PreparedStatement pst = con.prepareStatement(sql.toString());
			pst.setString(1, initialDate);
			pst.setString(2, finalDate);
			pst.setFetchSize(100);

			final ResultSet rs = pst.executeQuery();
			List<String[]> dataList = new ArrayList<String[]>();
			while (rs.next()) {
				Record record = MarcUtils.iso2709ToRecord(rs.getBytes(3));

				String assetHolding = rs.getString("accession_number");
				String creationDate = rs.getString(2);
				String[] data = new String[6];
				MarcDataReader dataReader = new MarcDataReader(record);
				data[0] = creationDate;
				data[1] = assetHolding;
				data[2] = dataReader.getTitle(false);
				data[3] = dataReader.getAuthorName(false);
				data[4] = dataReader.getPublicationYear();

				Record holding = MarcUtils.iso2709ToRecord(rs.getBytes(4));
				MarcDataReader holdingReader = new MarcDataReader(holding);
				data[5] = holdingReader.getSourceAcquisitionDate();
				dataList.add(data);
			}
			dto.setData(dataList);
			return dto;
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public HoldingCreationByDateReportDto getHoldingCreationByDateReportData(String initialDate, String finalDate) {
		HoldingCreationByDateReportDto dto = new HoldingCreationByDateReportDto();
		dto.setInitialDate(initialDate);
		dto.setFinalDate(finalDate);

		String totalBiblioMain = "0";
		String totalBiblioWork = "0";
		String totalHoldingMain = "0";
		String totalHoldingWork = "0";

		StringBuilder sqlTotal = new StringBuilder();
		sqlTotal.append(" SELECT to_char(created, 'DD/MM/YYYY'), user_name, count(created_by) ");
		sqlTotal.append(" FROM holding_creation_counter ");
		sqlTotal.append(" WHERE created >= to_date(?, 'DD-MM-YYYY') ");
		sqlTotal.append(" and created <= to_date(?, 'DD-MM-YYYY') ");
		sqlTotal.append(" GROUP BY user_name, to_char(created, 'DD/MM/YYYY') ");
		sqlTotal.append(" ORDER BY to_char(created, 'DD/MM/YYYY'), user_name; ");

		try (Connection con = this.getConnection()) {

			try (PreparedStatement st = con.prepareStatement(sqlTotal.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					List<String[]> data = new ArrayList<String[]>();
					while (rs.next()) {
						String[] arrayData = new String[4];
						arrayData[0] = rs.getString(1); // data
						arrayData[1] = rs.getString(2); // nome
						arrayData[2] = rs.getString(3); // total
						data.add(arrayData);
					}
					dto.setData(data);
				}
			}

			StringBuilder sqlBiblioMain = new StringBuilder();
			sqlBiblioMain.append(" SELECT COUNT(id) FROM biblio_records ");
			sqlBiblioMain.append(" WHERE database = 'main' AND created >= to_date(?, 'DD-MM-YYYY') ");
			sqlBiblioMain.append(" AND created <= to_date(?, 'DD-MM-YYYY'); ");

			try (PreparedStatement st = con.prepareStatement(sqlBiblioMain.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					if (rs != null && rs.next()) {
						totalBiblioMain = rs.getString(1);
					}
				}
			}

			StringBuilder sqlBiblioWork = new StringBuilder();
			sqlBiblioWork.append(" SELECT COUNT(id) FROM biblio_records ");
			sqlBiblioWork.append(" WHERE database = 'work' AND created >= to_date(?, 'DD-MM-YYYY') ");
			sqlBiblioWork.append(" AND created <= to_date(?, 'DD-MM-YYYY'); ");

			try (PreparedStatement st = con.prepareStatement(sqlBiblioWork.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					if (rs != null && rs.next()) {
						totalBiblioWork = rs.getString(1);
					}
				}
			}

			StringBuilder sqlHoldingMain = new StringBuilder();
			sqlHoldingMain.append(" SELECT COUNT(*) FROM biblio_holdings ");
			sqlHoldingMain.append(" WHERE database = 'main' AND created >= to_date(?, 'DD-MM-YYYY') ");
			sqlHoldingMain.append(" AND created <= to_date(?, 'DD-MM-YYYY'); ");

			try (PreparedStatement st = con.prepareStatement(sqlHoldingMain.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);
				try (ResultSet rs = st.executeQuery()) {
					if (rs != null && rs.next()) {
						totalHoldingMain = rs.getString(1);
					}
				}
			}

			StringBuilder sqlHoldingWork = new StringBuilder();
			sqlHoldingWork.append(" SELECT COUNT(*) FROM biblio_holdings ");
			sqlHoldingWork.append(" WHERE database = 'work' AND created >= to_date(?, 'DD-MM-YYYY') ");
			sqlHoldingWork.append(" AND created <= to_date(?, 'DD-MM-YYYY'); ");

			try (PreparedStatement st = con.prepareStatement(sqlHoldingWork.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);
				try (ResultSet rs = st.executeQuery()) {
					if (rs != null && rs.next()) {
						totalHoldingWork = rs.getString(1);
					}
				}
			}

			dto.setTotalBiblioMain(totalBiblioMain);
			dto.setTotalBiblioWork(totalBiblioWork);
			dto.setTotalHoldingMain(totalHoldingMain);
			dto.setTotalHoldingWork(totalHoldingWork);
			return dto;

		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public LendingsByDateReportDto getLendingsByDateReportData(String initialDate, String finalDate) {
		LendingsByDateReportDto dto = new LendingsByDateReportDto();
		dto.setInitialDate(initialDate);
		dto.setFinalDate(finalDate);
		int lended = 0, late = 0, total = 0;

		StringBuilder sqlLent = new StringBuilder();
		sqlLent.append(" SELECT count(*) FROM lendings ");
		sqlLent.append(" WHERE created >= to_date(?, 'DD-MM-YYYY') ");
		sqlLent.append(" AND created <= to_date(?, 'DD-MM-YYYY') ");
		sqlLent.append(" AND return_date is null; ");

		StringBuilder sqlHistory = new StringBuilder();
		sqlHistory.append(" SELECT count(*) FROM lendings ");
		sqlHistory.append(" WHERE created >= to_date(?, 'DD-MM-YYYY') ");
		sqlHistory.append(" AND created <= to_date(?, 'DD-MM-YYYY') ");
		sqlHistory.append(" AND return_date is not null; ");

		StringBuilder sqlLate = new StringBuilder();
		sqlLate.append(" SELECT count(*) FROM lendings ");
		sqlLate.append(" WHERE created >= to_date(?, 'DD-MM-YYYY') ");
		sqlLate.append(" AND created <= to_date(?, 'DD-MM-YYYY') ");
		sqlLate.append(" AND expected_return_date < to_date(?, 'DD-MM-YYYY') ");
		sqlLate.append(" AND return_date is null; ");

		try (Connection con = this.getConnection()){

			try (PreparedStatement st = con.prepareStatement(sqlLent.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					if (rs.next()) {
						lended = rs.getInt(1);
					}
				}
			}


			try (PreparedStatement st = con.prepareStatement(sqlHistory.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					if (rs.next()) {
						total = rs.getInt(1) + lended;
					}
				}
			}


			try (PreparedStatement st = con.prepareStatement(sqlLate.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);
				st.setString(3, dd_MM_yyyy.format(new Date()));

				try (ResultSet rs = st.executeQuery()) {
					if (rs.next()) {
						late = rs.getInt(1);
					}
				}
			}

			String[] totals = { String.valueOf(total), String.valueOf(lended), String.valueOf(late) };
			dto.setTotals(totals);

			StringBuilder sqlTop20 = new StringBuilder();
			sqlTop20.append(" SELECT b.id, count(b.id) AS rec_count ");
			sqlTop20.append(" FROM lendings l, biblio_records b, biblio_holdings h ");
			sqlTop20.append(" WHERE l.holding_id = h.id ");
			sqlTop20.append(" AND l.created >= to_date(?, 'DD-MM-YYYY') ");
			sqlTop20.append(" AND l.created <= to_date(?, 'DD-MM-YYYY') ");
			sqlTop20.append(" AND h.record_id = b.id ");
			sqlTop20.append(" GROUP BY b.id ");
			sqlTop20.append(" ORDER BY rec_count desc ");
			sqlTop20.append(" LIMIT 20;");

			try (PreparedStatement st = con.prepareStatement(sqlTop20.toString())) {
				st.setString(1, initialDate);
				st.setString(2, finalDate);

				try (ResultSet rs = st.executeQuery()) {
					List<String[]> data = new ArrayList<String[]>();

					BiblioRecordBO biblioBO = BiblioRecordBO.getInstance(this.schema);

					while (rs.next()) {
						Integer biblioId = rs.getInt(1);
						Integer count = rs.getInt(2);
						RecordDTO recordDto = biblioBO.get(biblioId);
						Record record = MarcUtils.iso2709ToRecord(recordDto.getIso2709());
						MarcDataReader dataReader = new MarcDataReader(record);
						String[] arrayData = new String[3];
						arrayData[0] = String.valueOf(count);// count
						arrayData[1] = dataReader.getTitle(false);// title
						arrayData[2] = dataReader.getAuthorName(false);// author
						data.add(arrayData);
					}

					dto.setData(data);

					return dto;
				}
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public LateLendingsDto getLateReturnLendingsReportData() {
		LateLendingsDto dto = new LateLendingsDto();

		StringBuilder sql = new StringBuilder();
		sql.append("SELECT u.id as userid, u.name as username, l.expected_return_date, b.iso2709 ");
		sql.append("FROM lendings l, users u, biblio_records b, biblio_holdings h ");
		sql.append("WHERE l.expected_return_date < to_date(?, 'DD-MM-YYYY') ");
		sql.append("AND l.user_id = u.id ");
		sql.append("AND l.holding_id = h.id ");
		sql.append("AND h.record_id = b.id ");
		sql.append("AND l.return_date is null; ");

		try (Connection con = this.getConnection();
				PreparedStatement st = con.prepareStatement(sql.toString());
				) {

			st.setString(1, dd_MM_yyyy.format(new Date()));

			try (ResultSet rs = st.executeQuery()) {
				List<String[]> data = new ArrayList<String[]>();

				while (rs.next()) {
					String[] lending = new String[4];
					lending[0] = String.valueOf(rs.getInt("userid")); //matricula
					lending[1] = rs.getString("username"); // nome do usuario
					Record record = MarcUtils.iso2709ToRecord(
							new String(rs.getBytes("iso2709"), Constants.DEFAULT_CHARSET));
					MarcDataReader dataReader = new MarcDataReader(record);
					lending[2] = dataReader.getTitle(false); // titulo
					lending[3] = dd_MM_yyyy.format(rs.getDate("expected_return_date"));
					data.add(lending);
				}
				dto.setData(data);
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}

		return dto;
	}

	public SearchesByDateReportDto getSearchesByDateReportData(String initialDate, String finalDate) {
		SearchesByDateReportDto dto = new SearchesByDateReportDto();

		final String sql = " select count(created), to_char(created, 'YYYY-MM-DD')"
				+ " from biblio_searches "
				+ " WHERE created >= to_date(?, 'DD-MM-YYYY') "
				+ " and created <= to_date(?, 'DD-MM-YYYY') "
				+ " group by to_char(created, 'YYYY-MM-DD') "
				+ " order by to_char(created, 'YYYY-MM-DD') ASC;";

		try (Connection con = this.getConnection();
				PreparedStatement st = con.prepareStatement(sql);)
		{
			st.setString(1, initialDate);
			st.setString(2, finalDate);

			try (ResultSet rs = st.executeQuery()) {
				dto.setInitialDate(initialDate);
				dto.setFinalDate(finalDate);
				List<String[]> data = new ArrayList<String[]>();
				dto.setData(data);
				SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
				while (rs.next()) {
					String[] arrayData = new String[2];
					arrayData[0] = rs.getString(1);
					Date date = format.parse(rs.getString(2));
					arrayData[1] = dd_MM_yyyy.format(date);
					dto.getData().add(arrayData);
				}

				return dto;
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public AllUsersReportDto getAllUsersReportData() {
		AllUsersReportDto dto = new AllUsersReportDto();
		dto.setTypesMap(new HashMap<String, Integer>());
		dto.setData(new HashMap<String, List<String>>());

		StringBuilder firstSql = new StringBuilder();
		firstSql.append("SELECT count(u.type) as total, t.description, t.id ");
		firstSql.append("FROM users u, users_types t ");
		firstSql.append("WHERE u.type = t.id ");
		firstSql.append("AND u.status <> '" + UserStatus.INACTIVE.toString() + "' ");
		firstSql.append("GROUP BY u.type, t.description, t.id ");
		firstSql.append("ORDER BY t.description;");

		try (Connection con = this.getConnection();
				Statement createStatement = con.createStatement();
				ResultSet rs = createStatement.executeQuery(firstSql.toString());
				){

			while (rs.next()) {
				final String description = rs.getString("description");
				final Integer count = rs.getInt("total");
				dto.getTypesMap().put(description, count);

				StringBuilder secondSql = new StringBuilder();
				secondSql.append("SELECT name, id, created, modified from users ");
				secondSql.append("WHERE type = '" + rs.getInt("id") + "' ");
				secondSql.append("ORDER BY name; ");

				ResultSet rs2 = createStatement.executeQuery(secondSql.toString());
				List<String> dataList = new ArrayList<String>();
				while (rs2.next()) {
					dataList.add(rs2.getString("name") + "\t"
							+ rs2.getInt("id") + "\t"
							+ dd_MM_yyyy.format(rs2.getDate("created")) + "\t"
							+ dd_MM_yyyy.format(rs2.getDate("modified")) + "\n");
				}
				dto.getData().put(description, dataList);
			}

			return dto;
		} catch (Exception e) {
			throw new DAOException(e);
		}

	}

	public RequestsByDateReportDto getRequestsByDateReportData(String initialDate, String finalDate) {
		RequestsByDateReportDto dto = new RequestsByDateReportDto();
		dto.setInitialDate(initialDate);
		dto.setFinalDate(finalDate);

		StringBuilder sql = new StringBuilder();
		sql.append(" SELECT DISTINCT o.id, r.requester, r.item_title, r.quantity, i.unit_value, o.total_value ");
		sql.append(" FROM orders o, requests r, request_quotation i ");
		sql.append(" WHERE o.quotation_id = i.quotation_id ");
		sql.append(" AND r.id = i.request_id ");
		sql.append(" AND r.created >= to_date(?, 'DD-MM-YYYY') ");
		sql.append(" AND r.created <= to_date(?, 'DD-MM-YYYY') ");
		sql.append(" ORDER BY o.id; ");

		try (Connection con = this.getConnection();
				PreparedStatement st = con.prepareStatement(sql.toString());){

			st.setString(1, initialDate);
			st.setString(2, finalDate);

			try (ResultSet rs = st.executeQuery()) {
				List<String[]> dataList = new ArrayList<String[]>();

				dto.setData(dataList);

				while (rs.next()) {
					String[] data = new String[6];
					data[0] = rs.getString("id");
					data[1] = rs.getString("requester");
					data[2] = rs.getString("item_title");
					data[3] = rs.getString("quantity");
					data[4] = rs.getString("unit_value");
					data[5] = rs.getString("total_value");
					dataList.add(data);
				}

				return dto;
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public TreeMap<String, Set<Integer>> searchAuthors(String authorName, RecordDatabase database) {
		TreeMap<String, Set<Integer>> results = new TreeMap<String, Set<Integer>>();

		String[] terms = authorName.split(" ");

		StringBuilder sql = new StringBuilder();
		sql.append("SELECT DISTINCT B.id, B.iso2709 FROM biblio_records B ");
		sql.append("INNER JOIN biblio_idx_fields I ON I.record_id = B.id ");
		sql.append("WHERE B.database = ? ");
		sql.append("AND I.indexing_group_id = 1 ");

		for (int i = 0; i < terms.length; i++) {
			if (StringUtils.isNotBlank(terms[i])) {
				sql.append("AND B.id in (SELECT record_id FROM biblio_idx_fields WHERE word >= ? and word < ?) ");
			}
		}

		try (Connection con = this.getConnection();
				PreparedStatement st = con.prepareStatement(sql.toString())
				){

			int index = 1;

			st.setString(index++, database.toString());

			for (int i = 0; i < terms.length; i++) {
				if (StringUtils.isNotBlank(terms[i])) {
					st.setString(index++, terms[i]);
					st.setString(index++, TextUtils.incrementLastChar(terms[i]));
				}
			}

			try (ResultSet rs = st.executeQuery()) {
				if (rs != null) {
					while (rs.next()) {
						Integer id = rs.getInt("id");
						String iso2709 = new String(rs.getBytes("iso2709"), Constants.DEFAULT_CHARSET);
						Record record = MarcUtils.iso2709ToRecord(iso2709);
						String name = new MarcDataReader(record).getAuthor(false);
						if (results.containsKey(name)) {
							Set<Integer> ids = results.get(name);
							ids.add(id);
						} else {
							Set<Integer> ids = new HashSet<Integer>();
							ids.add(id);
							results.put(name, ids);
						}
					}
				}

				return results;
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public BibliographyReportDto getBibliographyReportData(String authorName, Integer[] recordIdArray) {
		BibliographyReportDto dto = new BibliographyReportDto();
		dto.setAuthorName(authorName);

		StringBuilder sql = new StringBuilder();
		sql.append(" SELECT iso2709 FROM biblio_records WHERE id IN (");
		sql.append(StringUtils.repeat("?", ", ", recordIdArray.length));
		sql.append(") ORDER BY id ASC; ");

		try (Connection con = this.getConnection();
				PreparedStatement st = con.prepareStatement(sql.toString());
				) {

			for (int i = 0; i < recordIdArray.length; i++) {
				st.setInt(i + 1, recordIdArray[i]);
			}

			try (ResultSet rs = st.executeQuery()) {
				List<String[]> data = new ArrayList<String[]>();
				while (rs.next()) {
					String iso2709 = new String(rs.getBytes("iso2709"), Constants.DEFAULT_CHARSET);
					Record record = MarcUtils.iso2709ToRecord(iso2709);
					MarcDataReader dataReader = new MarcDataReader(record);
					String[] lending = new String[5];
					lending[0] = dataReader.getTitle(false);
					lending[1] = dataReader.getEdition();
					lending[2] = dataReader.getEditor();
					lending[3] = dataReader.getPublicationYear();
					lending[4] = dataReader.getShelfLocation();
					data.add(lending);
				}
				dto.setData(data);

				return dto;
			}
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	public ReservationReportDto getReservationReportData() {
		ReservationReportDto dto = new ReservationReportDto();

		StringBuilder sql = new StringBuilder();
		sql.append(" SELECT u.name, u.id, b.iso2709, ");
		sql.append(" to_char(r.created, 'DD/MM/YYYY') AS created ");
		sql.append(" FROM reservations r, users u, biblio_records b ");
		sql.append(" WHERE r.user_id = u.id ");
		sql.append(" AND r.record_id = b.id ");
		sql.append(" AND r.record_id is not null ");
		sql.append(" ORDER BY u.name ASC; ");

		try (Connection con = this.getConnection();
				Statement st = con.createStatement();
				ResultSet rs = st.executeQuery(sql.toString());) {

			List<String[]> biblioReservations = new ArrayList<String[]>();

			while (rs.next()) {
				String[] reservation = new String[5];
				reservation[0] = rs.getString("name");
				reservation[1] = String.valueOf(rs.getInt("id"));
				String iso2709 = new String(rs.getBytes("iso2709"), Constants.DEFAULT_CHARSET);
				Record record = MarcUtils.iso2709ToRecord(iso2709);
				MarcDataReader dataReader = new MarcDataReader(record);
				reservation[2] = dataReader.getTitle(false);
				reservation[3] = dataReader.getAuthorName(false);
				reservation[4] = rs.getString("created");
				biblioReservations.add(reservation);
			}
			dto.setBiblioReservations(biblioReservations);

			return dto;
		} catch (Exception e) {
			throw new DAOException(e);
		}
	}

	private final Connection getConnection() throws SQLException {
		Connection con = this.getDataSource().getConnection();

		if (this.schema != null) {
			con.createStatement().execute("SET search_path = '" + this.schema + "', public, pg_catalog;");
		}

		return con;
	}

	private final DataSource getDataSource() {
		DataSource ds = null;

		try {
			InitialContext cxt = new InitialContext();

			ds = (DataSource) cxt.lookup("java:comp/env/jdbc/" + this.dataSourceName);
		} catch (Exception e) {
			throw new DAOException(e);
		}

		if (ds == null) {
			System.out.println("[DAO.Constructor] Data Source not found.");
			throw new RuntimeException("Data Source not found!");
		}

		return ds;
	}

	private PreparedStatement _createPreparedStatementWith100Rows(String sql, Connection con)
			throws SQLException {
		PreparedStatement pst = con.prepareStatement(sql);

		pst.setFetchSize(100);

		return pst;
	}
}