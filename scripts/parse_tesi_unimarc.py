#!/usr/bin/env python
# -*- coding: utf-8 -*-

# 16/09/2019
# Mapping table Dublin core/Unimarc at:
#   https://docs.google.com/spreadsheets/d/1EXCAiCwhG6JevRonMv62luJjL0OQ-7r6n7pnOyaDGHw/edit#gid=1153896167

from lxml.etree import parse
from lxml.etree import tostring
import sys
import os
import urllib
import time
from datetime import datetime
import re

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


metadati_filename = sys.argv[1]
oai_001_filename = sys.argv[2] # Mapping oai_identifer|bid degli scarichi precedenti per verificare se tesi sia gia' stata acquisita precedentemente
nbn_filename = sys.argv[3] # 20/04/2020
opac_archive_name = sys.argv[4]
wayback_http_server = sys.argv[5]
ambiente=sys.argv[6]
bid_ctr_filename=sys.argv[7]
record_aggiornati_filename=sys.argv[8]
record_nuovi_filename=sys.argv[9]
record_cancellati_filename=sys.argv[10]
year2d=sys.argv[11]

# print sys.argv

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


# quit()

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
    'jumpoffpage': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'statements': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[2]/didl:Statement/',
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
    'diiIdentifier': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'type': 'dc:type',
    'thesis.degree.level': 'dc:thesis.degree.level',
    'components': 'metadata/didl:DIDL/didl:Item/didl:Component',
     'resource': 'didl:Resource'
}

recs=int(0)

if opac_archive_name == "ASTERISCO":
    opac_archive_name = '*'

#f_lista_tesi= open(lista_tesi,"w+")


for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    # if recs > 1:
    #     print "" # riga di separazione tra record
    # print "--> record # "+str(recs)

    componenturl=""
    tesi2=""
    record_status=""  # n=new c=corrected

    oaiidentifier = record.find(paths['oaiidentifier']).text
    status = record.find(paths['status'])

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
                #   $a	Standard Number
                print "=017  80$a"+oaiidentifier+"\n"

            else:
                # f_record_cancellati.write(oaiidentifier+"|"+"TEST0000000"+"\n")
                sys.stderr.write("Record cancellato "+oaiidentifier+" non presente negli scarichi precedenti\n")


    # if status is None:
    else:

        # oaiidentifier = record.find(paths['oaiidentifier']).text
        # print "--> cerca "+paths['oaiidentifier']
        # sys.stderr.write("--> trovato "+oaiidentifier+"\n")

        # if not componenturl in oai_001_dict.keys():


        if oaiidentifier in oai_001_dict.keys():
            # sys.stderr.write("OAI record "+oaiidentifier+" IN WARC reuse ")

            # Tesi presente in scarichi precedenti
            # prendere bid
            bid=oai_001_dict[oaiidentifier]
            # sys.stderr.write("bid="+bid+"\n");

            # segnalare record gia' presente
            f_record_aggiornati.write(oaiidentifier+"|"+bid+"\n")
            record_status="c"

            # # 017 OTHER STANDARD IDENTIFIER
            # #   $a	Standard Number
            # sys.stdout.write("=017  80$a"+oaiidentifier+"\n")
        else:
            # genera bid "TD"+2 cifre per anno+6 cifre per contatore
            bid="TD"+year2d+'{:06d}'.format(bid_ctr)
            f_record_nuovi.write(oaiidentifier+"|"+bid+"\n")
            record_status="n"
            bid_ctr+=1



        # if jumpoffpage is a urn transform to an handle http link
        jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
        # print "--> paths['jumpoffpage'] "+paths['jumpoffpage']
        # print "--> jumpoffpage="+jumpoffpage

        if "urn" in jumpoffpage:
            jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
        else:
            jumpoffpageurl = jumpoffpage

        # print "--> jumpoffpageurl="+jumpoffpageurl

        # LDR RECORD LABEL
        print "=LDR  -0001"+record_status+"am  22----- n 450 "

        # 001 RECORD IDENTIFIER
        print "=001  "+bid

        # 005 Date and Time of Latest Transaction
        oaiidatestamp = record.find(paths['oaidatestamp']).text.replace("-", "").replace(":", "").replace("T", "").replace("Z", "")
        print "=005  "+oaiidatestamp+".0"


        for statements in record.findall(paths['statements'], namespaces=ns):
            diiIdentifier = record.xpath(paths['diiIdentifier'], namespaces=ns)[0].text.encode().strip()


            # # LDR RECORD LABEL
            # print "=LDR  -0001"+record_status+"am  22----- n 450 "
            #
            # # 001 RECORD IDENTIFIER
            # # print "=001  "+oai_001_dict[oaiidentifier]
            # print "=001  "+bid


#            f_lista_tesi.write("%s" % oaiidentifier)


            # 017 OTHER STANDARD IDENTIFIER
            #   $a	Standard Number
            #       Campo ripetuto per ogni ripetizione di //dc:identifier. Non creato se corrisponde a //dii:Identifier[0]
            sys.stdout.write("=017  80$a"+oaiidentifier+"\n")

            if oaiidentifier in oai_nbn_dict.keys():
                nbn_identifier=oai_nbn_dict[oaiidentifier]
                sys.stdout.write("=017  80$a"+nbn_identifier+"\n")


            identifiers=statements.findall(paths['identifiers'], namespaces=ns)
            if identifiers is not None:
                size=len(identifiers)
                # print "size="+str(size)
                i=0
                if size > i:
                    found_diiIdentifier=0
                    while i < size:
                        identifier=identifiers[i].text.encode('utf-8')
                        sys.stdout.write("=017  80$a"+identifier+"\n")
                        if identifier == diiIdentifier:
                            found_diiIdentifier=1
                        i+=1
                    if found_diiIdentifier == 1:
                        sys.stdout.write("=017  80$a"+diiIdentifier+"\n")


            dates=statements.findall(paths['dates'], namespaces=ns)
            # out_date="=100    $a"+"20190501d----------k--ita-50----ba"+" "
            out_date="=100    $a"+"20190501d        --k--ita-50----ba"+" "
            if dates is not None:
                dates_len= len(dates)
                if (dates_len > 0):
                    date=dates[0].text.encode('utf-8')

                    # 100 GENERAL PROCESSING DATA
                    #   $a	GENERAL PROCESSING DATA
                    #       Al posto di ‘xxxx’ vanno i primi 4 char di dc:data[0] se tutti e quattro sono numeri; altrimenti va ‘----'
                    sub = date[ 0 : 0 + 4]
                    if sub.isdigit():
                        # print "=100    $a"+"20190501d"+sub+"------k--ita-50----ba"+" "
                        # out_date = "=100    $a"+"20190501d"+sub+"------k--ita-50----ba"+" "
                        out_date = "=100    $a"+"20190501d"+sub+"    --k--ita-50----ba"+" "

            #         else:
            #             print "=100    $a"+"20190501d----------k--ita-50----ba"+" "
            print out_date


            # 101 LANGUAGE OF THE ITEM
            #   $a	Language of Text, Soundtrack etc.
            #       Sottocampo ripetuto per ogni ripetizione di dc:language
            languages=statements.findall(paths['languages'], namespaces=ns)
            if languages is not None:
                size=len(languages)
                i=0
                if size > i:
                    sys.stdout.write("=101  1 ")
                    while i < size:
                        language=languages[i].text.encode('utf-8')
                        sys.stdout.write("$a"+language)
                        i+=1
                    sys.stdout.write("\n")



            # 200 TITLE AND STATEMENT OF RESPONSIBILITY
            #   $a	Title Proper
            #   $b	General Material Designation
            titles=statements.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
#                print "TITLES="+str(size)
                if size > 0:
                    if titles[0].text is not None:
                        title=titles[0].text.encode('utf-8')
                        title_r=title.replace("\n", " ")
                    else:
                        title=""
                    sys.stdout.write("=200  1 $a"+title_r+"$bTesi di dottorato\n")
#                    f_lista_tesi.write("|%s\n" % title_r)



            # 210 PUBLICATION, DISTRIBUTION, ETC.
            #   $c	Name of Publisher, Distributor, etc.
            #   $d	Date of Publication, Distribution, etc.
            publishers=statements.findall(paths['publishers'], namespaces=ns)
            if publishers is not None:
                size=len(publishers)
                i=0
                if size > i:
                    sys.stdout.write("=210   1")
                    while i < size:
                        publisher=publishers[i].text.encode('utf-8')

                        if i < dates_len:
                            date=dates[i].text.encode('utf-8')
                            sys.stdout.write("$c"+publisher+"$d"+date)
                        else:
                            sys.stdout.write("$c"+publisher)

                        i+=1
                    sys.stdout.write("\n")


            # 300 GENERAL NOTES
            #   $a	Text of Note
            #       ‘Diritti: ‘ + //dc:rights
            #       ‘In relazione con: ‘ + //dc:relation
            #       'Copertura: ‘ + //dc:coverage
            #       ‘Sorgente: ‘ + //dc:source

            rights=statements.findall(paths['rights'], namespaces=ns)
            relation=statements.find(paths['relation'], namespaces=ns)

            # TODO !!!!!
            # try:
            #     coverage=statements.find(paths['coverage'], namespaces=ns)
            # except IndexError:
            #     print "NO coverage"
            #     del coverage
            #
            # try:
            #     source=statements.find(paths['source'], namespaces=ns)
            # except IndexError:
            #     print "NO source"
            #     del source

            # if 'coverage' in globals():
            #     print "coverage="+coverage
            #     # .text.encode('utf-8')
            # if 'source' in globals():
            #     print "source="+source
                # .text.encode('utf-8')

#             if rights is not None:
#                 print "=300    $adiritti: "+rights.text.encode('utf-8')

            if rights is not None:
                size=len(rights)
#                print "TITLES="+str(size)
                if size > 0:
                    sys.stdout.write("=300    ")
                    i=0;
                    while i < size:
                        if rights[i].text is None:
                            sys.stdout.write("$adiritti: ") # empty tag
                            i+=1
                            continue
                        right=rights[i].text.encode('utf-8')
                        sys.stdout.write("$adiritti: "+right)
                        i+=1
                    sys.stdout.write("\n")


            if relation is not None:
                if relation.text is not None:
                    print "=300    $aIn relazione con "+relation.text.encode('utf-8')


            # 328 DISSERTATION (THESIS) NOTE
            #   $b Dissertation or thesis details and type of degree
            #   $c	Discipline of degree
            #   $e	Body granting the degree
                        # thesis degree level
                        # print "=998  $a"+thesis_degree_level
            #

            thesis_degree_level=statements.find(paths['thesis.degree.level'], namespaces=ns)
            subjects=statements.findall(paths['subjects'], namespaces=ns)
            if subjects is not None:
                size=len(subjects)
                i=0
                if size > i:
                    sys.stdout.write("=328   0$btesi di dottorato")
                    if thesis_degree_level is not None:
                        sys.stdout.write(" (livello "+thesis_degree_level.text.encode('utf-8')+")")

                    while i < size:
                        if subjects[i].text is not None:
                            subject=subjects[i].text.encode('utf-8')

                            # Prendere solo prima ripetizione SSD
                            ssd = re.search("\w+\/[0-9]{2}", subject)
                            if ssd:
                                # end = int(str(ssd.end()))
                                # sys.stdout.write("$c"+ssd.string[0:end])
                                sys.stdout.write("$c"+subject)
                                # sys.stdout.write("\n")
                                break;
                        i+=1



                    if len(publishers) > 0:
                        publisher=publishers[0].text.encode('utf-8')
                        sys.stdout.write("$e"+publisher)
                    sys.stdout.write("\n")




            # 330 SUMMARY OR ABSTRACT
            # $a Text of Note
            #    Campo ripetuto per ogni ripetizione di //dc:description
            descriptions=statements.findall(paths['descriptions'], namespaces=ns)
            if descriptions is not None:
                size=len(descriptions)
                i=0
                if size > i:
                    sys.stdout.write("=330    ")
                    while i < size:
                        if descriptions[i].text is not None:
                            description=descriptions[i].text.encode('utf-8').replace("\n", " ")
                            sys.stdout.write("$a"+description)
                        i+=1
                    sys.stdout.write("\n")




            # 336 TYPE OF ELECTRONIC RESOURCE NOTE
            #   $a  Text of Note
            #       Campo ripetuto per ogni ripetizione di //dc:format
            formats=statements.findall(paths['formats'], namespaces=ns)
            if formats is not None:
                size=len(formats)
                i=0
                if size > i:
                    sys.stdout.write("=336    ")
                    while i < size:
                        if formats[i].text is not None:
                            format=formats[i].text.encode('utf-8')
                            sys.stdout.write("$a"+format)
                        i+=1
                    sys.stdout.write("\n")




            # 517 OTHER VARIANT TITLES
            # Campo ripetuto per ogni ripetizione di //dc:title dalla seconda in poi

            if titles is not None:
                size=len(titles)
#                print "size="+str(size)
                i=1
                if size > i:
                    sys.stdout.write("=517  1 ")
                    while i < size:
#                        print "i="+str(i)
                        if titles[i].text is None:
                            i+=1
                            continue
                        title=titles[i].text.encode('utf-8')
                        sys.stdout.write("$c"+title)
                        i+=1
                    sys.stdout.write("\n")


            # 610 UNCONTROLLED SUBJECT TERMS
            #   $a	Subject Term
            #       Sempre e solo se dc.subject non inizia con un SSD, se no è 689. Per ogni ripetizione da fare un nuovo tag
            if subjects is not None:
                size=len(subjects)
                i=0
                if size > i:
                    while i < size:
                        if subjects[i].text is None:
                            i+=1
                            continue
                        subject=subjects[i].text.encode('utf-8')
                        ssd = re.search("\w+\/[0-9]{2}", subject)
                        if ssd:
                            end = int(str(ssd.end()))

                            # sys.stdout.write("$X"+ssd.string[0:end]+"$Y"+ssd.string[end+2:])

                            sys.stdout.write("=689  0 ")
                            sys.stdout.write("$a"+ssd.string[0:end])
                            s = ssd.string[end+1:]
                            if len(s):
                                sys.stdout.write("$b"+ s)
                            sys.stdout.write("$cTDR")
                            sys.stdout.write("\n")
                        else:
                            sys.stdout.write("=610  0 ")
                            sys.stdout.write("$a"+subject);
                            sys.stdout.write("\n")
                        i+=1
            creators=statements.findall(paths['creators'], namespaces=ns)
            # 700 PERSONAL NAME - PRIMARY RESPONSIBILITY
            #   $a	Entry Element
            if creators is not None:
                size_creators=len(creators)
                if size_creators:
                    print "=700   0$a"+creators[0].text.encode('utf-8')

                # 701 PERSONAL NAME - ALTERNATIVE RESPONSIBILITY
                #   $a	Entry Element
                # Ogni ripetizione crea un nuovo tag
                i=1
                if size_creators > i:
                    while i < size_creators:
                        sys.stdout.write("=701   0")
                        creator=creators[i].text.encode('utf-8')
                        sys.stdout.write("$a"+creator)
                        sys.stdout.write("\n")
                        i+=1

            # 702 PERSONAL NAME - SECONDARY RESPONSIBILITY
            # Ogni ripetizione crea un nuovo tag
            contributors=statements.findall(paths['contributors'], namespaces=ns)
            if contributors is not None:
                size=len(contributors)
                i=0
                if size > i:
                    while i < size:
                        sys.stdout.write("=702   0")
                        if contributors[i].text is not None:
                            contributor=contributors[i].text.encode('utf-8')
                            sys.stdout.write("$a"+contributor+"\n")
                        i+=1

            # ORIGINATING SOURCE
            # valori fissi
            print "=801   3$aIT"+"$bIT-FI0098"


            # 856 ELECTRONIC LOCATION AND ACCESS
            #   $u	Uniform Resource Identifier
            #   $2	Link al sito originale

#             if identifiers is not None:
#                 size=len(identifiers)
# #                 if size:
# #                     identifier=identifiers[0].text.encode('utf-8')
# #                     print "=856  4 $uTO DO link a bncf wayback machine?"+"$2"+identifier
#                 i=0
#                 while i < size:
#                     if identifiers[i].text is not None:
#                         identifier=identifiers[i].text.encode('utf-8')
#                         if identifier.startswith('http'):
#                             # print "=856  4 $uTO DO link a bncf wayback machine?"+"$2"+identifier
#                             if identifier in timestamp_dict.keys():
#                                 ts=timestamp_dict[identifier]
#                                 print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+ts+"/"+identifier+"$2"+identifier
#                             else:
#                                 print "=856  4 $uWAYBACK URL NOT FOUND"+"$2"+identifier
#                     i+=1


            # Cerchiamo i seed per vedere se sono finiti nel warc file
            # Pagina descrittiva della tesi
            # if jumpoffpageurl in timestamp_dict.keys():
            #     # ts=timestamp_dict[jumpoffpageurl]
            #     # if ambiente == "esercizio" or ambiente == "nuovo_esercizio":
            #         # print "=856  4 $u"+wayback_http_server+"/"+jumpoffpageurl+"$2"+jumpoffpageurl
            #     # else:
            #         # print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+ts+"/"+jumpoffpageurl+"$2"+jumpoffpageurl
            #     print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+jumpoffpageurl+"$2"+jumpoffpageurl
            #
            #     # sys.stderr.write("\nWAYBACK URL FOUND")
            # else:
            #     print "=856  4 $uWAYBACK URL NOT FOUND"+"$2"+jumpoffpageurl

            print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+jumpoffpageurl+"$2"+jumpoffpageurl





            # Risorse della tesi (full text)
            for components in record.findall(paths['components'], namespaces=ns):
                component = components.find(paths['resource'], namespaces=ns)
                componenturl = urllib.quote(component.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")
                # if componenturl in timestamp_dict.keys():
                #     # ts=timestamp_dict[componenturl]
                #     # if ambiente == "esercizio" or ambiente == "nuovo_esercizio":
                #         # print "=856  4 $u"+wayback_http_server+"/"+componenturl+"$2"+componenturl
                #     # else:
                #         # print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+ts+"/"+componenturl+"$2"+componenturl
                #
                #     print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+componenturl+"$2"+componenturl
                #
                # else:
                #     print "=856  4 $uWAYBACK URL NOT FOUND"+"$2"+componenturl

                print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+componenturl+"$2"+componenturl


            # 977 library code (local)
            #   $a  Coded value
            print "=977    $a CR"   # Per la Nazionale di Roma


            # 997 library code (local)
            #   $a	Coded value
            print "=997    $aCF"    # Per la Nazionale di Firenze

            # Work type (local)
            print "=FMT    $aTD"

            print "" # riga di separazione tra record

# Salviamo il contatore (che puo' essere stato aggiornato)
f_bid_ctr = open(bid_ctr_filename, "w")
f_bid_ctr.write( str(bid_ctr)+"\n")
f_bid_ctr.close()
f_record_aggiornati.close()
f_record_nuovi.close()
f_record_cancellati.close()
