

# Rielaboarazione file xml esportato da DB per generazione unimarc
sed  '1s;^;<?xml version="1.0" encoding="UTF-8"?>\n<records>\n;' db.xml.srt > db.xml.srt.record
echo "</records>" >> db.xml.srt.record
sed -i 's/ns6:dc/oai_dc:dc/g' db.xml.srt.record
sed -i 's/xmlns:ns6=/xmlns:oai_dc=/g' db.xml.srt.record
sed -i 's|xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/"|xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"|g' db.xml.srt.record
sed -i 's/\x08/ /g' db.xml.srt.record
sed -i 's/\x00/ /g' db.xml.srt.record
sed -i 's/\x1A/ /g' db.xml.srt.record

# sed -i 's/&lt;/</g' db.xml.srt.record NO causa problemi di tag non riconosciuti
# sed -i 's/&gt;/>/g' db.xml.srt.record


=================================

sed  '1s;^;<?xml version="1.0" encoding="UTF-8"?>\n<records>\n;' tmp.xml > tmp.xml.record
echo "</records>" >> tmp.xml.record
sed -i 's/\x08/ /g' tmp.xml.record
sed -i 's/\x00/ /g' tmp.xml.record
sed -i 's/\x1A/ /g' tmp.xml.record

# sed -i 's/&lt;/</g' tmp.xml.record NO causa problemi di tag non riconosciuti
# sed -i 's/&gt;/>/g' tmp.xml.record




sed -n 1482655,1482658p db.xml.srt.record

KO
<oai_dc:dc
xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/"
xmlns:dc="http://purl.org/dc/elements/1.1/"
xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd
urn:mpeg:mpeg21:2002:02-DIDL-NS
http://standards.iso.org/ittf/PubliclyAvailableStandards/MPEG-21_schema_files/did/didl.xsd
urn:mpeg:mpeg21:2005:01-DIP-NS
http://standards.iso.org/ittf/PubliclyAvailableStandards/MPEG-21_schema_files/dip/dip.xsd">

OK
<oai_dc:dc
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:d="urn:mpeg:mpeg21:2002:02-DIDL-NS"
xmlns:doc="http://www.lyncode.com/xoai"
xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">


=LDR  -0001nam  22----- n 450
=001  TD11177604
=017  oai:u-gov:UNIVR.IT:RI_PRD:351825
=100    $a20190501d2011------k--ita-50----ba
=101  1 $aita
=200  1 $aLetteratura e cultura nei periodici veronesi di fine Ottocento$bTesi di dottorato
=300    $adiritti: info:eu-repo/semantics/openAccess$adiritti: NO EMBARGO
=328   0$btesi di dottorato$c[SSD]:L-FIL-LET/11 - LETTERATURA ITALIANA CONTEMPORANEA
=330    $aVerso la fine dell’Ottocento, la città di Verona rivela attraverso il giornalismo letterario e politico un dinamismo culturale inedito, che per certi aspetti la allontana
