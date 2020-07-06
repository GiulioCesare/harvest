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

filename = sys.argv[1]
tesi_cancellate = sys.argv[2]
tree = parse(filename)

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

# print "#Data archiviazione MD|Data della tesi|Autore della tesi|Tutor della tesi|Titolo della tesi|Soggetto|Handle|URL della tesi|OAI identifier"

f_tesi_cancellate= open(tesi_cancellate,"w+")


print "#OAI identifier|URL tesi (dii:identifier)|Titolo della tesi"

for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    # print ""
    # print "--> record # "+str(recs)

    status = record.find(paths['status'])
    # print "status="+str(status)

    if status is not None:
        oaiidentifier = record.find(paths['oaiidentifier']).text
        f_tesi_cancellate.write("%s\n" % oaiidentifier)

    else:

        oaiidentifier = record.find(paths['oaiidentifier']).text
        # print "--> cerca "+paths['oaiidentifier']
        # print "--> trovato "+oaiidentifier

        # if jumpoffpage is a urn transform to an handle http link
        jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
        # print "--> paths['jumpoffpage'] "+paths['jumpoffpage']
        # print "--> jumpoffpage="+jumpoffpage

        if "urn" in jumpoffpage:
            jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
        else:
            jumpoffpageurl = jumpoffpage

#        print jumpoffpageurl
        # print oaiidentifier
        sys.stdout.write(oaiidentifier+"|"+jumpoffpageurl)

        for statements in record.findall(paths['statements'], namespaces=ns):
            diiIdentifier = record.xpath(paths['diiIdentifier'], namespaces=ns)[0].text.strip()


            # 200 TITLE AND STATEMENT OF RESPONSIBILITY
            #   $a	Title Proper
            #   $b	General Material Designation
            titles=statements.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
                if size > 0:
                    title=titles[0].text.encode('utf-8').replace("\n", " ")
                    sys.stdout.write("|"+title+"\n")
                else:
                    sys.stdout.write("|titolo non dichiarato\n")
            else:
                sys.stdout.write("|titolo non dichiarato\n")

f_tesi_cancellate.close()
