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

# sys.stderr.write("arg1 "+sys.argv[1]+"\n")
# sys.stderr.write("arg2 "+sys.argv[2]+"\n")
# sys.stderr.write("arg3 "+sys.argv[3]+"\n")
# sys.stderr.write("arg4 "+sys.argv[4]+"\n")
# sys.stderr.write("arg5 "+sys.argv[5]+"\n")


metadati_filename = sys.argv[1]
oai_001_filename = sys.argv[2]
# wayback_index_timestamp = sys.argv[3]
opac_archive_name = sys.argv[3]
wayback_http_server = sys.argv[4]
ambiente=sys.argv[5]
# no_bids_filename=sys.argv[6]
new_bids_filename=sys.argv[6]


# timestamp_dict = {}
# oai_001_dict = {}



# def load_oai_001 (filename):
#     f = open(filename, "r")
#     for line in f:
#     #     key=line.strip()
#     #     oai_001_dict[key]="value"
#         data_ar=line.split('|')
#         key=data_ar[0].strip()      # oai identifier as key
#         value=data_ar[1].strip()            # unimarc 001 as value
#         oai_001_dict[key]=value
#     f.close()

    # for k, v in oai_001_dict.items():
    #     sys.stderr.write(k+' is  '+v+"\n")


# load_oai_001(oai_001_filename)
f = open(oai_001_filename, "r")
# f_no_bids = open(no_bids_filename, "w")
f_new_bids = open(new_bids_filename, "w")


tree = parse(metadati_filename)

ns = {
    'didl': 'urn:mpeg:mpeg21:2002:02-DIDL-NS',
    'oai_dc': 'http://www.openarchives.org/OAI/2.0/oai_dc/',
    'dc': 'http://purl.org/dc/elements/1.1/',
    'dii': 'urn:mpeg:mpeg21:2002:01-DII-NS'
}

paths = {
    'oaiidentifier': 'identifier',
    'oaidatestamp': 'header/datestamp',

    'dc_records': 'oai_dc:dc',

    'dates': 'dc:date',
    'languages': 'dc:language',
    'titles': 'dc:title',
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
    'identifiers': 'dc:identifier',


    # 'jumpoffpage': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    # 'statements': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[2]/didl:Statement/',





    'diiIdentifier': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'type': 'dc:type',
    'thesis.degree.level': 'dc:thesis.degree.level',

    'components': 'metadata/didl:DIDL/didl:Item/didl:Component',
    # 'component': 'didl:Resource'

     'resource': 'didl:Resource'
}

recs=int(0)
recs_no_bids=int(0)

if opac_archive_name == "ASTERISCO":
    opac_archive_name = '*'

#f_lista_tesi= open(lista_tesi,"w+")
# for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
# for record in tree.xpath('.//title'):

root = tree.getroot()

BID_NUM=1   #00001
bid_generati=0

for record in root.findall(paths['dc_records'], namespaces=ns):


    # print "--> record # "+str(recs)

    # status = record.find(paths['status'])
    # print "status="+str(status)

    # componenturl=""
    # tesi2=""

    # oaiidentifier = record.find(paths['oaiidentifier']).text
    # if not oaiidentifier in oai_001_dict.keys():
    #     sys.stderr.write("OAI record "+oaiidentifier+" NOT IN WARC\n")
    #     continue;
    # print "--> trovato "+oaiidentifier.text


    # 001 RECORD IDENTIFIER
    kv=f.readline() #.rstrip()
    # if not kv:
    #     continue; # empty line


    ar=kv.split("|")
    # print ar
    if len(ar) < 3:
        continue



    # sys.stdout.write("=001  "+ar[1])
    oaiidentifier=ar[0]
    # bid=ar[1]
    anno=ar[2].rstrip()

    # print "'"+bid+"'"

    # if not bid:
        # bid="TD"+anno[2:]+str(BID_NUM);
    bid="TD"+anno[2:]+'{:06d}'.format(BID_NUM)

    BID_NUM += 1;
    bid_generati +=1;
    # recs_no_bids +=1
    # f_no_bids.write(kv)
    # continue

    f_new_bids.write(oaiidentifier+"|"+bid+"\n")

    # sys.stderr.write(oaiidentifier+"*"+bid)

    recs += 1
    # if recs > 1:
    #     print "" # riga di separazione tra record

    # LDR RECORD LABEL
    print "=LDR  -0001nam  22----- n 450 "

    print"=001  "+bid

    # 005 Date and Time of Latest Transaction
    # oaiidatestamp = record.find(paths['oaidatestamp']).text.replace("-", "").replace(":", "").replace("T", "").replace("Z", "")
    # print "=005  "+oaiidatestamp+".0"

    # 017 OTHER STANDARD IDENTIFIER
    # sys.stdout.write("=017  80$a"+oaiidentifier+"\n")
    print "=017  80$a"+ar[0]


    dates=record.findall(paths['dates'], namespaces=ns)
    out_date = "=100    $a"+"20190501d----------k--ita-50----ba"+" "
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
                out_date = "=100    $a"+"20190501d"+sub+"------k--ita-50----ba"+" "
            # else:
            #     print "=100    $a"+"20190501d----------k--ita-50----ba"+" "
    print out_date


    # 101 LANGUAGE OF THE ITEM
    #   $a	Language of Text, Soundtrack etc.
    #       Sottocampo ripetuto per ogni ripetizione di dc:language
    languages=record.findall(paths['languages'], namespaces=ns)
    if languages is not None:
        size=len(languages)
        i=0
        if size > i:
            sys.stdout.write("=101  1 ")
            while i < size:
                if languages[i].text is None:
                    i+=1
                    continue
                language=languages[i].text.encode('utf-8')
                sys.stdout.write("$a"+language)
                i+=1
            sys.stdout.write("\n")

    # 200 TITLE AND STATEMENT OF RESPONSIBILITY
    #   $a	Title Proper
    #   $b	General Material Designation
    titles=record.findall(paths['titles'], namespaces=ns)
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
    publishers=record.findall(paths['publishers'], namespaces=ns)
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

    rights=record.findall(paths['rights'], namespaces=ns)
    relation=record.find(paths['relation'], namespaces=ns)


    if rights is not None:
        size=len(rights)
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
    thesis_degree_level=record.find(paths['thesis.degree.level'], namespaces=ns)
    subjects=record.findall(paths['subjects'], namespaces=ns)
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
    descriptions=record.findall(paths['descriptions'], namespaces=ns)
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
    formats=record.findall(paths['formats'], namespaces=ns)
    if formats is not None:
        size=len(formats)
        i=0
        if size > i:
            start="=336    "
            while i < size:
                if formats[i].text is not None:
                    format=formats[i].text.encode('utf-8')
                    sys.stdout.write(start+"$a"+format)
                    start=""
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
    creators=record.findall(paths['creators'], namespaces=ns)
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
    contributors=record.findall(paths['contributors'], namespaces=ns)
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

    # 28/02/2002    Da un campione di dati dal Db sembrerebbe esserci solo un identifier per record
    identifiers=record.findall(paths['identifiers'], namespaces=ns)
    if identifiers is not None:
        size=len(identifiers)
        if size:
            i=0
            while i < size:
                if identifiers[i].text is None:
                    i+=1
                    continue
                identifier=identifiers[i].text.encode('utf-8')
                if identifier.startswith("http"):
                    # print "=856  4 $u"+wayback_http_server+"/"+opac_archive_name+"/"+identifier+"$2"+identifier
                    print "=856  4 $uhttp://memoria.depositolegale.it/*/"+identifier+"$2"+identifier
                i+=1

    # 997 library code (local)
    #   $a	Coded value
    print "=997    $aCF"

    # Work type (local)
    print "=FMT    $aTD"

    print "" # riga di separazione tra record


sys.stderr.write("Elaborati " + str(recs) + " record\n")
sys.stderr.write("Bid generati " + str(bid_generati) + " \n")
sys.stderr.write("Bid gia' presenti " + str(recs-bid_generati) + " \n")


f.close()
# f_no_bids.close()
f_new_bids.close()
