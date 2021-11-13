package biblivre.cataloging.dataimport.impl;

import biblivre.cataloging.dataimport.BaseImportProcessor;
import java.io.InputStream;
import org.marc4j.MarcXmlReader;

public class MarcXMLImportProcessor extends BaseImportProcessor {

    @Override
    protected void initMarcReader(InputStream inputStream) {
        marcReader = new MarcXmlReader(inputStream);
    }
}
