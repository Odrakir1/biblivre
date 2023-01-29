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

import biblivre.administration.reports.dto.BaseReportDto;
import biblivre.administration.reports.dto.SummaryReportDto;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import java.util.Collections;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;

@Component
public class SummaryReport extends BaseBiblivreReport {

    private Integer index;

    @Override
    protected BaseReportDto getReportData(ReportsDTO dto) {
        Integer order = 1;
        if (StringUtils.isNotBlank(dto.getOrder())
                && StringUtils.isNumeric(dto.getOrder().trim())) {
            order = Integer.valueOf(dto.getOrder().trim());
        }
        switch (order) {
            case 1:
                this.index = 6;
                break; // dewey
            case 2:
                this.index = 0;
                break; // title
            case 3:
                this.index = 1;
                break; // author
            default:
                this.index = 6; // dewey
        }
        return ReportsDAOImpl.getInstance().getSummaryReportData(dto.getDatabase());
    }

    @Override
    protected void generateReportBody(Document document, BaseReportDto reportData)
            throws Exception {
        SummaryReportDto dto = (SummaryReportDto) reportData;
        Paragraph p1 = new Paragraph(this.getText("administration.reports.title.summary"));
        p1.setAlignment(Element.ALIGN_CENTER);
        document.add(p1);
        document.add(new Phrase("\n"));
        PdfPTable table = new PdfPTable(10);
        table.setWidthPercentage(100f);
        createHeader(table);
        Collections.sort(
                dto.getData(),
                (o1, o2) -> {
                    if (o1 == null || o1[this.index] == null) {
                        return -1;
                    }

                    if (o2 == null || o2[this.index] == null) {
                        return 1;
                    }

                    return o1[this.index].compareTo(o2[this.index]);
                });
        PdfPCell cell;
        for (String[] data : dto.getData()) {
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[6])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[0])));
            cell.setColspan(2);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[1])));
            cell.setColspan(2);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[2])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[3])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[4])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[5])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
            cell = new PdfPCell(new Paragraph(this.getSmallFontChunk(data[7])));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            table.addCell(cell);
        }
        document.add(table);
    }

    private void createHeader(PdfPTable table) {
        PdfPCell cell;
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.dewey"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.title"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setColspan(2);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.author"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setColspan(2);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.isbn"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.editor"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.year"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText("administration.reports.field.edition"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
        cell =
                new PdfPCell(
                        new Paragraph(
                                this.getBoldChunk(
                                        this.getText(
                                                "administration.reports.field.holdings_count"))));
        cell.setBackgroundColor(this.HEADER_BG_COLOR);
        cell.setBorderWidth(this.HEADER_BORDER_WIDTH);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
    }

    @Override
    public ReportType getReportType() {
        return ReportType.SUMMARY;
    }
}
