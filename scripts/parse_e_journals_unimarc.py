#!/usr/bin/env python
# -*- coding: utf-8 -*-


from lxml.etree import parse
from lxml.etree import tostring
import sys
import os
import urllib

# sys.stderr.write("arg1 '"+sys.argv[1]+"'\n")
# sys.stderr.write("arg2 '"+sys.argv[2]+"'\n")
# sys.stderr.write("arg3 '"+sys.argv[3]+"'\n")
# sys.stderr.write("arg4 '"+sys.argv[4]+"'\n")
# sys.stderr.write("arg5 '"+sys.argv[5]+"'\n")
# sys.stderr.write("arg6 '"+sys.argv[6]+"'\n")
# sys.stderr.write("arg7 '"+sys.argv[7]+"'\n")
# sys.stderr.write("arg8 '"+sys.argv[8]+"'\n")
# sys.stderr.write("arg9 '"+sys.argv[9]+"'\n")
# sys.stderr.write("arg10 '"+sys.argv[10]+"'\n")
# sys.stderr.write("arg11 '"+sys.argv[11]+"'\n")




# metadati_filename = sys.argv[1]
# nbn_filename = sys.argv[2] # 20/04/2020
# opac_archive_name = sys.argv[3]
# wayback_http_server = sys.argv[4]
# ambiente=sys.argv[5]

# 29/03/2021
metadati_filename = sys.argv[1]
oai_001_filename = sys.argv[2] # Mapping oai_identifer|bid degli scarichi precedenti per verificare se tesi sia gia' stata acquisita precedentemente
nbn_filename = sys.argv[3] 
opac_archive_name = sys.argv[4]
wayback_http_server = sys.argv[5]
ambiente=sys.argv[6]
bid_ctr_filename=sys.argv[7]
record_aggiornati_filename=sys.argv[8]
record_nuovi_filename=sys.argv[9]
record_cancellati_filename=sys.argv[10]
year2d=sys.argv[11]

# timestamp_dict = {}
oai_001_dict = {}
def load_oai_001 (filename):
    f = open(filename, "r")
    for line in f:
    #     key=line.strip()
    #     oai_001_dict[key]="value"

        if line[0] == '#' or not line.strip():
            continue

        data_ar=line.split('|')
        key=data_ar[0]#.strip()      # oai identifier as key
        value=data_ar[1].rstrip()    # BID as value
        oai_001_dict[key]=value
    f.close()

    # for k, v in oai_001_dict.items():
    #     sys.stderr.write(k+' is  '+v+"\n")

oai_nbn_dict = {}
def load_oai_nbn (filename):
    # sys.stderr.write( 'filename='+filename+"\n")

    f = open(filename, "r")
    for line in f:
        # sys.stderr.write( 'line='+line+"\n")

        if line[0] == '#' or not line.strip():
            continue

        # if not line.strip():
        #     continue

        data_ar=line.split('|')
        key=data_ar[0]#.strip()      # oai identifier as key
        value=data_ar[1].rstrip()    # nbn identifier as value
        oai_nbn_dict[key]=value


    f.close()

load_oai_nbn(nbn_filename)
load_oai_001(oai_001_filename)
tree = parse(metadati_filename)

f_bid_ctr = open(bid_ctr_filename, "r")
bid_ctr= int(f_bid_ctr.readline().rstrip())
# sys.stderr.write( 'bid_ctr='+str(bid_ctr)+"\n")
# bid_ctr+=1
# sys.stderr.write( 'bid_ctr='+str(bid_ctr)+"\n")
f_bid_ctr.close()


f_record_aggiornati = open(record_aggiornati_filename, "w")
f_record_nuovi = open(record_nuovi_filename, "w")
f_record_cancellati = open(record_cancellati_filename, "w")


ns = {
    'didl': 'urn:mpeg:mpeg21:2002:02-DIDL-NS',
    'oai_dc': 'http://www.openarchives.org/OAI/2.0/oai_dc/',
    'dc': 'http://purl.org/dc/elements/1.1/',
    'dii': 'urn:mpeg:mpeg21:2002:01-DII-NS'
}

paths = {
    'oaiidentifier': 'header/identifier',
    'oaidatestamp': 'header/datestamp',
    'status': 'header[@status]',
    #'jumpoffpage': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'metadata': 'metadata/',
    'identifiers': 'dc:identifier',
    'languages': 'dc:language',
    'titles': 'dc:title',
    'dates': 'dc:date',
    'publishers': 'dc:publisher',
    'subjects': 'dc:subject',
    'descriptions': 'dc:description',
    'formats': 'dc:format',
    'creators': 'dc:creator',
    'contributors': 'dc:contributor',
    'rights': 'dc:rights',
    'relation': 'dc:relation',
    'coverage': 'dc:coverage',
    'source': 'dc:source',
    'type': 'dc:type',
    'thesis.degree.level': 'dc:thesis.degree.level',
    'components': 'metadata/didl:DIDL/didl:Item/didl:Component',
    'resource': 'didl:Resource'
}

recs=int(0)

if opac_archive_name == "ASTERISCO":
    opac_archive_name = '*'


for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    print ""
    # print "--> record # "+str(recs)

    record_status=""  # n=new c=corrected

    status = record.find(paths['status'])
    # print "status="+str(status)

    # if status is None:
    if status is not None:
        # sys.stderr.write("status="+status.attrib['status'])
        stato=status.attrib['status']
        if stato == "deleted":
            # sys.stderr.write("stato="+stato)

            if oaiidentifier in oai_001_dict.keys():
                bid=oai_001_dict[oaiidentifier]

                # Scriviamo il record cancellato in elenco dei record cancellati
                # --------------------------------------------------------------
                # sys.stderr.write("Record cancellato "+oaiidentifier+"\n")
                f_record_cancellati.write(oaiidentifier+"|"+bid+"\n")


                # Scriviamo il record cancellato in unimarc
                # -----------------------------------------
                record_status="d"

                # LDR RECORD LABEL
                print "=LDR  -0001"+record_status+"am  22----- n 450 "

                # 001 RECORD IDENTIFIER
                # print "=001  "+oai_001_dict[oaiidentifier]
                print "=001  "+bid

                # 017 OTHER STANDARD IDENTIFIER
                #   $a  Standard Number
                print "=017  80$a"+oaiidentifier+"\n"

            else:
                sys.stderr.write("Record cancellato "+oaiidentifier+" non presente negli scarichi precedenti\n")


    else:
        oaiidentifier = record.find(paths['oaiidentifier']).text
        # print "--> cerca "+paths['oaiidentifier']
        # print "--> trovato "+oaiidentifier

        # if jumpoffpage is a urn transform to an handle http link
        # jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
        # print "--> paths['jumpoffpage'] "+paths['jumpoffpage']
        # print "--> jumpoffpage="+jumpoffpage

        # if "urn" in jumpoffpage:
        #    jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
        # else:
        #    jumpoffpageurl = jumpoffpage

        # print "--> jumpoffpageurl="+jumpoffpageurl

        if oaiidentifier in oai_001_dict.keys():
            # sys.stderr.write("OAI record "+oaiidentifier+" IN WARC reuse ")

            # Record presente in scarichi precedenti
            # prendere bid
            bid=oai_001_dict[oaiidentifier]
            # sys.stderr.write("bid="+bid+"\n");

            # segnalare record gia' presente
            f_record_aggiornati.write(oaiidentifier+"|"+bid+"\n")
            record_status="c"

            # # 017 OTHER STANDARD IDENTIFIER
            # #   $a    Standard Number
            # sys.stdout.write("=017  80$a"+oaiidentifier+"\n")
        else:
            # genera bid "TD"+2 cifre per anno+6 cifre per contatore
            bid="EJ"+year2d+'{:06d}'.format(bid_ctr)
            f_record_nuovi.write(oaiidentifier+"|"+bid+"\n")
            record_status="n"
            bid_ctr+=1
            # print "BID:"+bid


        for metadata in record.findall(paths['metadata'], namespaces=ns):
            #diiIdentifier = record.xpath(paths['diiIdentifier'], namespaces=ns)[0].text.strip()



            # subject=statements.find(paths['subject'], namespaces=ns).text.encode('utf-8')
            # contributor_dc=statements.find(paths['contributor'], namespaces=ns).text.encode('utf-8')
            # type=statements.find(paths['type'], namespaces=ns).text.encode('utf-8')
            # format=statements.find(paths['format'], namespaces=ns).text.encode('utf-8')
            # language=statements.find(paths['language'], namespaces=ns).text.encode('utf-8')
            # if contributor_dc:
            #     title=title+"$g"+contributor_dc

            # LDR RECORD LABEL
            #   tiporecord ='l'  risorsa elettronica
            #   livello bibliografico = 's' periodico

            print "=LDR  -0001nls  22----- n 450 "

            # 001 RECORD IDENTIFIER
            # print "=001    "+oaiidentifier
            print "=001    "+bid

            # 005 Date and Time of Latest Transaction
            oaiidatestamp = record.find(paths['oaidatestamp']).text.replace("-", "").replace(":", "").replace("T", "").replace("Z", "")
            print "=005    "+oaiidatestamp+".0"


            # 011 INTERNATIONAL STANDARD SERIAL NUMBER
            #   $a  Number (ISSN)
            #       Creato se vi si trova dentro una stringa nella forma \d\d\d\d-\d\d\d\d]
            source=metadata.findall(paths['source'], namespaces=ns)
            if source is not None:
                size=len(source)
                i=0
                if size > i:
                    while i < size:
                        source1=source[i].text.encode('utf-8')
                        sub1 = source1[ 0 : 0 + 4]
                        sub2 = source1[ 4 : 4 + 1]
                        sub3 = source1[ 5 : 5 + 4]
                        if sub1.isdigit() and sub2=="-" and sub3.isdigit():
                            # print "campo ="+sub1+"-"+sub2
                            print "=011    $a"+source1
                        i+=1

            # 017 OTHER STANDARD IDENTIFIER
            #   $a  Standard Number
            #       Campo Ripetuto per ogni ripetizione di //dc:identifier.
            #       Non creato se corrisponde a //header/identifier. Non creato se inizia con ‘http’

            sys.stdout.write("=017  80$a"+oaiidentifier+"\n")


            if oaiidentifier in oai_nbn_dict.keys():
                nbn_identifier=oai_nbn_dict[oaiidentifier]
                sys.stdout.write("=017  80$a"+nbn_identifier+"\n")


            identifiers=metadata.findall(paths['identifiers'], namespaces=ns)
            if identifiers is not None:
                size=len(identifiers)
                # print "size="+str(size)
                i=0
                if size > i:
                    while i < size:
                        identifier=identifiers[i].text.encode('utf-8')
                        if (identifier != oaiidentifier) and (not identifier.startswith('http')):
                            print "=017  80$a"+identifier
                        i+=1


            dates=metadata.findall(paths['dates'], namespaces=ns)
            date=dates[0].text.encode('utf-8')

            # 100 GENERAL PROCESSING DATA
            #   $a  GENERAL PROCESSING DATA
            #       Al posto di ‘xxxx’ vanno i primi 4 char di dc:data[0] se tutti e quattro sono numeri; altrimenti va ‘----'
            sub = date[ 0 : 0 + 4]
            if sub.isdigit():
                print "=100    $a"+"20190501d"+sub+"------k--ita-50----ba"+" "
            else:
                print "=100    $a"+"20190501d----------k--ita-50----ba"+" "



            # 101 LANGUAGE OF THE ITEM
            #   $a  Language of Text, Soundtrack etc.
            #       Sottocampo ripetuto per ogni ripetizione di dc:language
            languages=metadata.findall(paths['languages'], namespaces=ns)
            if languages is not None:
                size=len(languages)
                i=0
                if size > i:
                    while i < size:
                        language=languages[i].text.encode('utf-8')
                        print "=101  1$a"+language
                        i+=1


            # 200 TITLE AND STATEMENT OF RESPONSIBILITY
            #   $a  Title Proper
            #   $b  General Material Designation
            titles=metadata.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
                if size > 0:
                    if titles[0].text:
                        title=titles[0].text.encode('utf-8')
                        print "=200  1 $a"+title+"$bArticolo"


            # 210 PUBLICATION, DISTRIBUTION, ETC.
            #   $c  Name of Publisher, Distributor, etc.
            #   $d  Date of Publication, Distribution, etc.
            #   I sottocampi ripetuti per ogni ripetizione del campo DC relativo

            publishers=metadata.findall(paths['publishers'], namespaces=ns)
            if publishers is not None:
                size=len(publishers)
                size_dates=len(dates)
                i=0
                if size > i:
                    while i < size:
                        publisher=publishers[i].text.encode('utf-8')
                        if i < size_dates and dates[i].text:
                            date=dates[i].text.encode('utf-8')
                            print "=210   1"+"$c"+publisher+"$d"+date
                        i+=1


            # 300 GENERAL NOTES
            #   $a  Text of Note
            #       ‘Diritti: ‘ + //dc:rights
            #       ‘In relazione con: ‘ + //dc:relation
            #       'Copertura: ‘ + //dc:coverage
            #       ‘Sorgente: ‘ + //dc:source

            rights=metadata.findall(paths['rights'], namespaces=ns)
            if rights is not None:
                size=len(rights)
                # print "size="+str(size)
                i=0
                if size > i:
                    while i < size:
                        right=rights[i].text.encode('utf-8')
                        print "=300    "+"$aDiritti: "+right
                        i+=1

            relation=metadata.findall(paths['relation'], namespaces=ns)
            if relation is not None:
                size=len(relation)
                # print "size="+str(size)
                i=0
                if size > i:
                    while i < size:
                        relation1=relation[i].text.encode('utf-8')
                        print "=300    "+"$aIn relazione con: "+relation1
                        i+=1

            source=metadata.findall(paths['source'], namespaces=ns)
            if source is not None:
                size=len(source)
                # print "size="+str(size)
                i=0
                if size > i:
                    while i < size:
                        source1=source[i].text.encode('utf-8')
                        print "=300    "+"$aSorgente: "+source1
                        i+=1


            # 330 SUMMARY OR ABSTRACT
            # $a Text of Note
            #    Campo ripetuto per ogni ripetizione di //dc:description
            descriptions=metadata.findall(paths['descriptions'], namespaces=ns)
            if descriptions is not None:
                size=len(descriptions)
                i=0
                if size > i:
                    while i < size:
                        if descriptions[i].text:
                            description=descriptions[i].text.encode('utf-8')
                            print "=330    "+"$a"+description
                        i+=1


# DA FINIRE!!!!! TEST PROVENIENZA DA OJS
            # 332 TITLE AND STATEMENT OF RESPONSIBILITY
            # PREFERRED CITATION OF DESCRIBED MATERIALS
            #   $a  Text of Note
            #  Solo nel caso che l’export da Magazzini Digitali indichi la provenienza da OJS
            source=metadata.findall(paths['source'], namespaces=ns)
            if source is not None:
                size=len(source)
                if size > 0:
                    source0=source[0].text.encode('utf-8')
                    print "=332    $a"+source0




            # 336 TYPE OF ELECTRONIC RESOURCE NOTE
            #   $a  Text of Note
            #       Campo ripetuto per ogni ripetizione di //dc:format
            formats=metadata.findall(paths['formats'], namespaces=ns)
            if formats is not None:
                size=len(formats)
                i=0
                if size > i:
                    while i < size:
                        if formats[i].text:
                            format=formats[i].text.encode('utf-8')
                            print "=336    "+"$a"+format
                        i+=1




            # 517 OTHER VARIANT TITLES
            # Campo ripetuto per ogni ripetizione di //dc:title dalla seconda in poi
            if titles is not None:
                size=len(titles)
                i=1
                if size > i:
                    while i < size:
                        if titles[i].text:
                            titles=titles[i].text.encode('utf-8')
                            print "=517  1 "+"$c"+titles
                        i+=1


            # 610 UNCONTROLLED SUBJECT TERMS
            #   $a  Subject Term
            #       Per ogni ripetizione da fare un nuovo tag
            subjects=metadata.findall(paths['subjects'], namespaces=ns)
            if subjects is not None:
                size=len(subjects)
                i=0
                if size > i:
                    while i < size:
                        if subjects[i].text:
                            subject=subjects[i].text.encode('utf-8')
                            print "=610  0 "+subject
                        i+=1

            # 700 PERSONAL NAME - PRIMARY RESPONSIBILITY
            #   $a  Entry Element
            creators=metadata.findall(paths['creators'], namespaces=ns)
            if creators is not None:
                size_creators=len(creators)
                if size_creators:
                    if creators[0].text:
                        print "=700   0$a"+creators[0].text.encode('utf-8')


                    # 701 PERSONAL NAME - ALTERNATIVE RESPONSIBILITY
                    #   $a  Entry Element
                    # Ogni ripetizione crea un nuovo tag
                    i=1
                    if size_creators > i:
                        while i < size_creators:
                            if creators[i].text:
                                creator=creators[i].text.encode('utf-8')
                                print "=701   0$a"+creator
                            i+=1

            # 702 PERSONAL NAME - SECONDARY RESPONSIBILITY
            # Ogni ripetizione crea un nuovo tag
            contributors=metadata.findall(paths['contributors'], namespaces=ns)
            if contributors is not None:
                size=len(contributors)
                i=0
                if size > i:
                    while i < size:
                        if contributors[i].text:
                            contributor=contributors[i].text.encode('utf-8')
                            print "=702   0"+contributor
                        i+=1

            # ORIGINATING SOURCE
            # valori fissi
            print "=801 3$aIT"+"$bIT-FI0098"


            # 856 ELECTRONIC LOCATION AND ACCESS
            #   $u  Uniform Resource Identifier
            if identifiers is not None:
                size=len(identifiers)
                if size:
                    identifier=identifiers[0].text.encode('utf-8')
                    if identifier.startswith('http'):
                        # print "=856  4 $u"+identifier
                        print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+identifier+"$2"+identifier


            # 997 library code (local)
            #   $a  Coded value
            print "=997  $aCF"

            # Work type (local)
            print "=FMT  $aAR"




        # # for components in record.findall(paths['components'], namespaces=ns):
        # #     resource = components.find(paths['resource'], namespaces=ns)
        # #     resourceurl = urllib.quote(resource.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")
        # #     print "--> resourceurl="+str(resourceurl)
        # #     # print "{}".format(resourceurl)

# Salviamo il contatore (che puo' essere stato aggiornato)
f_bid_ctr = open(bid_ctr_filename, "w")
f_bid_ctr.write( str(bid_ctr)+"\n")
f_bid_ctr.close()
f_record_aggiornati.close()
f_record_nuovi.close()
f_record_cancellati.close()
