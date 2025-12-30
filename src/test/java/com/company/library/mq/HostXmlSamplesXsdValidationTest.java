package com.company.library.mq;

import static org.junit.jupiter.api.Assertions.fail;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
import javax.xml.XMLConstants;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import org.junit.jupiter.api.Test;
import org.xml.sax.SAXException;

class HostXmlSamplesXsdValidationTest {

    @Test
    void samplesShouldValidateAgainstXsd() throws Exception {
        Path samplesDir = Path.of("docs/mq/examples");
        Path xsdPath = Path.of("src/main/resources/contract/host-schema/library-loan.xsd");

        List<Path> samples = Files.list(samplesDir)
            .filter(path -> path.toString().endsWith(".xml"))
            .collect(Collectors.toList());

        if (samples.isEmpty()) {
            fail("No XML samples found under " + samplesDir.toAbsolutePath());
        }

        SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
        Schema schema = schemaFactory.newSchema(xsdPath.toFile());

        for (Path sample : samples) {
            try (InputStream in = Files.newInputStream(sample)) {
                schema.newValidator().validate(new StreamSource(in));
            } catch (SAXException ex) {
                fail("XSD validation failed for " + sample + ": " + ex.getMessage());
            }
        }
    }
}
