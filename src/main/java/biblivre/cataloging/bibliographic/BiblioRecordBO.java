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
package biblivre.cataloging.bibliographic;

import biblivre.administration.indexing.IndexingBO;
import biblivre.cataloging.RecordBO;
import biblivre.cataloging.RecordDTO;
import biblivre.cataloging.enums.RecordType;
import biblivre.cataloging.holding.HoldingBO;
import biblivre.cataloging.holding.HoldingDTO;
import biblivre.circulation.lending.LendingBO;
import biblivre.circulation.lending.LendingDTO;
import biblivre.circulation.reservation.ReservationBO;
import biblivre.core.exceptions.ValidationException;
import biblivre.marc.MarcDataReader;
import biblivre.marc.MarcUtils;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;
import org.marc4j.marc.Record;

public class BiblioRecordBO extends RecordBO {

    private HoldingBO holdingBO;

    public BiblioRecordBO(HoldingBO holdingBO) {
        super();
        this.holdingBO = holdingBO;
    }

    @Override
    public void populateDetails(RecordDTO rdto, int mask) {
        if (rdto == null) {
            return;
        }

        BiblioRecordDTO dto = (BiblioRecordDTO) rdto;

        if ((mask & RecordBO.MARC_INFO) != 0) {
            Record record = rdto.getRecord();

            if (record == null && rdto.getIso2709() != null) {
                record = MarcUtils.iso2709ToRecord(rdto.getIso2709());
            }

            if (record != null) {
                MarcDataReader marcDataReader = new MarcDataReader(record);

                dto.setAuthor(marcDataReader.getAuthor(true));
                dto.setTitle(marcDataReader.getTitle(false));
                dto.setIsbn(marcDataReader.getIsbn());
                dto.setIssn(marcDataReader.getIssn());
                dto.setIsrc(marcDataReader.getIsrc());
                dto.setPublicationYear(marcDataReader.getPublicationYear());
                dto.setShelfLocation(marcDataReader.getShelfLocation());
                dto.setSubject(marcDataReader.getSubject(true));
            }
        }

        Integer recordId = dto.getId();

        if (recordId == null || recordId <= 0) {
            return;
        }

        LendingBO lbo = LendingBO.getInstance(this.getSchema());
        ReservationBO rbo = ReservationBO.getInstance(this.getSchema());

        if ((mask & RecordBO.HOLDING_INFO) != 0) {
            int totalHoldings = holdingBO.count(recordId);
            int availableHoldings = holdingBO.countAvailableHoldings(recordId);
            int lentCount = 0;
            int reservedCount = 0;

            if (availableHoldings > 0) {
                lentCount = lbo.countLentHoldings(recordId);
                reservedCount = rbo.countReserved(dto);
            }

            dto.setHoldingsCount(totalHoldings);
            dto.setHoldingsAvailable(availableHoldings - lentCount);
            dto.setHoldingsLent(lentCount);
            dto.setHoldingsReserved(reservedCount);
        }

        if ((mask & RecordBO.HOLDING_LIST) != 0) {
            List<HoldingDTO> holdingsList = holdingBO.list(recordId);

            Collections.sort(holdingsList);

            for (HoldingDTO holding : holdingsList) {
                MarcDataReader marcDataReader = new MarcDataReader(holding.getRecord());

                String holdingLocation = marcDataReader.getShelfLocation();
                holding.setShelfLocation(
                        StringUtils.isNotBlank(holdingLocation)
                                ? holdingLocation
                                : dto.getShelfLocation());
            }

            dto.setHoldings(holdingsList);
        }

        if ((mask & RecordBO.LENDING_INFO) != 0) {
            List<HoldingDTO> holdingsList = dto.getHoldings();

            if (holdingsList == null) {
                holdingsList = holdingBO.list(recordId);
                Collections.sort(holdingsList);
            }

            List<LendingDTO> lendings = new ArrayList<>();
            for (HoldingDTO holding : holdingsList) {
                lendings.add(lbo.getCurrentLending(holding));
            }
        }
    }

    @Override
    public boolean save(RecordDTO dto) {
        dto.setDateOfLastTransaction();
        dto.setFixedLengthDataElements();

        if (this.rdao.save(dto)) {
            IndexingBO indexingBo = IndexingBO.getInstance(this.getSchema());
            indexingBo.reindex(RecordType.BIBLIO, dto);
            return true;
        }

        return false;
    }

    @Override
    public boolean update(RecordDTO dto) {
        dto.setDateOfLastTransaction();

        if (this.rdao.update(dto)) {
            IndexingBO indexingBo = IndexingBO.getInstance(this.getSchema());
            indexingBo.reindex(RecordType.BIBLIO, dto);
            return true;
        }

        return false;
    }

    @Override
    public boolean delete(RecordDTO dto) {

        //		HoldingBO holdingBo = new HoldingBO();
        //		LendingBO lendingBo = new LendingBO();
        //		List<HoldingDTO> holdings = holdingBo.list(record);
        //		for (HoldingDTO holding : holdings) {
        //			if (lendingBo.isLent(holding) || lendingBo.wasLent(holding)) {
        //				throw new RuntimeException("MESSAGE_DELETE_BIBLIO_ERROR");
        //			}
        //		}

        if (this.rdao.delete(dto)) {
            IndexingBO indexingBo = IndexingBO.getInstance(this.getSchema());
            indexingBo.deleteIndexes(RecordType.BIBLIO, dto);
            //			HoldingBO hbo = new HoldingBO();
            //			hbo.delete(dto);
        }
        return true;
    }

    @Override
    public boolean isDeleatable(HoldingDTO holding) throws ValidationException {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public Map<Integer, RecordDTO> map(Set<Integer> ids) {
        return super.map(ids, RecordBO.MARC_INFO | RecordBO.HOLDING_INFO | RecordBO.LENDING_INFO);
    }

    @Override
    public RecordType getRecordType() {
        return RecordType.BIBLIO;
    }
}
