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

tree = parse(metadati_filename)

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
    # 'component': 'didl:Resource'

     'resource': 'didl:Resource'
}

recs=int(0)



for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    if recs > 1:
        print "" # riga di separazione tra record
    # print "--> record # "+str(recs)

    status = record.find(paths['status'])
    # print "status="+str(status)


    if status is None:


        for statements in record.findall(paths['statements'], namespaces=ns):


            rights=statements.findall(paths['rights'], namespaces=ns)
            if rights is not None:
                size=len(rights)
                if size > 0:
                    sys.stdout.write(rights[0].text.encode('utf-8'))
                    i=1;
                    while i < size:
                        if rights[i].text is None:
                            # sys.stdout.write("$adiritti: ") # empty tag
                            i+=1
                            continue
                        sys.stdout.write(";"+rights[i].text.encode('utf-8'))
                        i+=1

            oaiidentifier = record.find(paths['oaiidentifier']).text
            sys.stdout.write("|"+oaiidentifier)

            jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
            if "urn" in jumpoffpage:
                jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
            else:
                jumpoffpageurl = jumpoffpage

            sys.stdout.write("|"+jumpoffpageurl)




            titles=statements.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
                if size > 0:
                    title=titles[0].text.encode('utf-8')
                    title_r=title.replace("\n", " ")
                    sys.stdout.write("|"+title_r)


            creators=statements.findall(paths['creators'], namespaces=ns)
            # 700 PERSONAL NAME - PRIMARY RESPONSIBILITY
            #   $a	Entry Element
            if creators is not None:
                size_creators=len(creators)
                if size_creators:
                    sys.stdout.write("|"+creators[0].text.encode('utf-8'))

                # 701 PERSONAL NAME - ALTERNATIVE RESPONSIBILITY
                #   $a	Entry Element
                # Ogni ripetizione crea un nuovo tag
                i=1
                if size_creators > i:
                    while i < size_creators:
                        sys.stdout.write("=701   0")
                        creator=creators[i].text.encode('utf-8')
                        sys.stdout.write(";"+creator)
                        i+=1

            # 702 PERSONAL NAME - SECONDARY RESPONSIBILITY
            # Ogni ripetizione crea un nuovo tag
            contributors=statements.findall(paths['contributors'], namespaces=ns)
            if contributors is not None:
                size=len(contributors)
                i=0
                if size > i:
                    while i < size:
                        if contributors[i].text is not None:
                            contributor=contributors[i].text.encode('utf-8')
                            sys.stdout.write(":"+contributor)
                        i+=1


            # # URL of resource
            # components=record.findall(paths['components'], namespaces=ns)
            # i=0;
            # for component in components:
            #     if component is not None:
            #         resource = component.find(paths['resource'], namespaces=ns)
            #         resourceurl = urllib.quote(resource.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")
            #         if i == 0:
            #             sys.stdout.write("|"+resourceurl)
            #         else:
            #             sys.stdout.write(";"+resourceurl)
            #     i+=1

            # sys.stdout.write("\n")
