package biblivre.administration.reports;

import java.awt.Color;
import java.util.function.Function;

import org.apache.commons.lang3.StringUtils;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;

public class ReportUtil {
	
	public static final Float SMALL_FONT_SIZE = 8f;
	public static final Float REPORT_FONT_SIZE = 10f;
	public static final Float PAGE_NUMBER_FONT_SIZE = 8f;
	public static final String ARIAL_FONT_NAME = "Arial";
	public static final Font SMALL_FONT = FontFactory.getFont(ARIAL_FONT_NAME, SMALL_FONT_SIZE, Font.NORMAL, Color.BLACK);
	public static final Font TEXT_FONT = FontFactory.getFont(ARIAL_FONT_NAME, REPORT_FONT_SIZE, Font.NORMAL, Color.BLACK);
	public static final Font BOLD_FONT = FontFactory.getFont(ARIAL_FONT_NAME, SMALL_FONT_SIZE, Font.BOLD, Color.BLACK);
	public static final Font HEADER_FONT = FontFactory.getFont(ARIAL_FONT_NAME, REPORT_FONT_SIZE, Font.BOLD, Color.BLACK);
	public static final Font FOOTER_FONT = FontFactory.getFont(FontFactory.COURIER, PAGE_NUMBER_FONT_SIZE, Font.BOLD, Color.BLACK);
	public static final Color HEADER_BACKGROUND_COLOR = new Color(239, 239, 239);
	public static final Float HEADER_BORDER_WIDTH = 0.8f;

	public static Chunk getNormalChunk(String text) {
		Chunk chunk = new Chunk(StringUtils.defaultIfEmpty(text, ""));
		chunk.setFont(TEXT_FONT);
		return chunk;
	}

	public static Chunk getBoldChunk(String text) {
		Chunk chunk = new Chunk(StringUtils.defaultIfEmpty(text, ""));
		chunk.setFont(BOLD_FONT);
		return chunk;
	}

	public static Chunk getSmallFontChunk(String text) {
		Chunk chunk = new Chunk(StringUtils.defaultIfEmpty(text, ""));
		chunk.setFont(SMALL_FONT);
		return chunk;
	}

	public static Chunk getHeaderChunk(String text) {
		Chunk chunk = new Chunk(StringUtils.defaultIfEmpty(text, ""));
		chunk.setFont(HEADER_FONT);
		return chunk;
	}

	public static void insertNewLine(Document document) throws DocumentException {
		document.add(new Phrase("\n"));
	}

	public static void insertChunkText(
			Document document, Function<String, Chunk> chunker, int alignment, String text)
		throws DocumentException {

		Paragraph p2 = new Paragraph(chunker.apply(text));
		p2.setAlignment(alignment);
		document.add(p2);
	}

	public static void insertHeaderColSpan2(PdfPTable table, String text) {
		PdfPCell cell = new PdfPCell(new Paragraph(getHeaderChunk(text)));

		applyBackgroundThenCenter(cell);
		cell.setColspan(2);

		table.addCell(cell);
	}

	public static void insertValue(PdfPTable table, String value) {
		PdfPCell cell = new PdfPCell(
				new Paragraph(getNormalChunk(value)));

		cell.setHorizontalAlignment(Element.ALIGN_LEFT);
		cell.setVerticalAlignment(Element.ALIGN_MIDDLE);

		table.addCell(cell);
	}

	public static void insertValueCenter(PdfPTable table, String value) {
		insertValueCenter(table, ReportUtil::getNormalChunk, value);
	}

	public static void insertValueCenter(
			PdfPTable table, Function<String, Chunk> chunker, String value) {
		PdfPCell cell = new PdfPCell(
				new Paragraph(chunker.apply(value)));

		cell.setHorizontalAlignment(Element.ALIGN_CENTER);
		cell.setVerticalAlignment(Element.ALIGN_MIDDLE);

		table.addCell(cell);
	}

	public static void insertHeaderTextWithBorder(PdfPTable table, String value) {
		insertTextWithBorder(table, ReportUtil::getHeaderChunk, value);
	}

	public static void insertTextWithBorder(
			PdfPTable table, Function<String, Chunk> chunker, String value) {
		PdfPCell cell = new PdfPCell(new Paragraph(chunker.apply(value)));

		cell.setBorderWidth(HEADER_BORDER_WIDTH);

		applyBackgroundThenCenter(cell);

		table.addCell(cell);
	}

	private static void applyBackgroundThenCenter(PdfPCell cell) {
		cell.setBackgroundColor(HEADER_BACKGROUND_COLOR);
		cell.setHorizontalAlignment(Element.ALIGN_CENTER);
		cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
	}

}