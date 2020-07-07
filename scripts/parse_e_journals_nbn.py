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

filename = sys.argv[1]
data_harvest = sys.argv[2]
metadata_url_base = sys.argv[3]     # Url base per scheda OAI dei metadati
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
    'dc_identifier': 'metadata/oai_dc:dc/dc:identifier',
    'dc_relation': 'metadata/oai_dc:dc/dc:relation',
    'jumpoffpage': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'statements': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[2]/didl:Statement/',
    'dates': 'metadata/oai_dc:dc/dc:date',
    'creators': 'metadata/oai_dc:dc/dc:creator',
    'titles': 'metadata/oai_dc:dc/dc:title',
    'identifiers': 'dc:identifier',
    'languages': 'dc:language',
    'publishers': 'dc:publisher',
    'subjects': 'metadata/oai_dc:dc/dc:subject',
    'descriptions': 'dc:description',
    'formats': 'dc:format',
    'contributors': 'metadata/oai_dc:dc/dc:contributor',
    'rights':'metadata/oai_dc:dc/dc:rights',
    'coverage': 'dc:coverage',
    'source': 'dc:source',
    'diiIdentifier': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'type': 'dc:type',
    'thesis.degree.level': 'dc:thesis.degree.level',
    'components': 'metadata/didl:DIDL/didl:Item/didl:Component',
    'resource': 'didl:Resource'




}
# Function definition is here
def print_elements( elements ):
    if elements is not None:
        size=len(elements)
        i=0
        current=0
        if size > i:
            while i < size:
                element=elements[i]
                if element.text is not None:
                    if current == 0:
                        sys.stdout.write("|")
                    else:
                        sys.stdout.write("")
                    element=element.text.encode('utf-8').rstrip()
                    sys.stdout.write(element.replace("\n",""))
                    return; # Take only the first one
                    current+=1
                i+=1
            if current == 0:
                sys.stdout.write("| ")
        else:
            sys.stdout.write("| ")
    else:
        sys.stdout.write("| ")
    return;


# recs=int(0)

# print "#Data archiviazione MD|Data dell'e_journal|Autore |Titolo dell'e_journal|URLs dell'e_journal|OAI identifier"

print "#OAI identifier|URL e-journal|URL memoria|URL OAI metadata|Titolo della tesi"



# Dizionario delle URL di un singolo record per scartare eventuali doppioni generati
url_dict={}

for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    # recs += 1
    # print ""
    # print "--> record # "+str(recs)

    status = record.find(paths['status'])
    # print "status="+str(status)

    if status is None:

        url_dict.clear()

        oaiidentifier = record.find(paths['oaiidentifier']).text

        # Scarichiamo l'OAI identifier in caso dobbiamo segnalare mancanti didl:resource
        sys.stdout.write(oaiidentifier);


        # URL of resource
        for dc_identifier in record.findall(paths['dc_identifier'], namespaces=ns):
            url=dc_identifier.text
            if re.match("^https?://.+$", url) and url not in url_dict:
                sys.stdout.write("|"+url+"|http://memoria.depositolegale.it/*/"+url)
                break

        sys.stdout.write("|"+metadata_url_base+oaiidentifier)

        elements=record.findall(paths['titles'], namespaces=ns)
        print_elements(elements)

        sys.stdout.write("\n")
