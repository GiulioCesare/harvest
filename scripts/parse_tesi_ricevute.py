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
data_harvest = sys.argv[2]
out_deleted_filename = sys.argv[3]
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
out_deleted=open(out_deleted_filename, "w")


print "#Data archiviazione MD|Data della tesi|Autore della tesi|Tutor della tesi|Titolo della tesi|Soggetto|Handle|URL della tesi|OAI identifier"
out_deleted.write("OAI identifier|Data cancellazione\n")

for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    # print ""
    # print "--> record # "+str(recs)

    status = record.find(paths['status'])

    if status is not None:
        # print "status="+str(status)
        # sys.stderr.write("status="+str(status)+"\n")
        attributes = status.attrib
        # print attributes

        if attributes["status"] == "deleted":
            oaiidentifier = record.find(paths['oaiidentifier']).text
            oaidatestamp = record.find(paths['oaidatestamp']).text

            # sys.stderr.write("attributes="+str(attributes)+"\n")
            out_deleted.write("deleted: "+oaiidentifier+"|"+oaidatestamp+"\n")
            


    if status is None:

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

        # print "--> jumpoffpageurl="+jumpoffpageurl


        for statements in record.findall(paths['statements'], namespaces=ns):
            diiIdentifier = record.xpath(paths['diiIdentifier'], namespaces=ns)[0].text.strip()



            identifiers=statements.findall(paths['identifiers'], namespaces=ns)

            sys.stdout.write(data_harvest)

            dates=statements.findall(paths['dates'], namespaces=ns)
            if dates is not None:
                dates_len= len(dates)
                if (dates_len > 0):
                    date=dates[0].text.encode('utf-8')

                    # 100 GENERAL PROCESSING DATA
                    #   $a	GENERAL PROCESSING DATA
                    #       Al posto di ‘xxxx’ vanno i primi 4 char di dc:data[0] se tutti e quattro sono numeri; altrimenti va ‘----'
                    sub = date[ 0 : 0 + 4]
                    if sub.isdigit():
                        # print "=100    $a"+date[ 0 : 0 + 7]
                        sys.stdout.write("|"+date[ 0 : 0 + 7])
                    else:
                        # print "=100    $a"+"date not defined"
                        sys.stdout.write("|data non dichiarata")
                else:
                    sys.stdout.write("|data non dichiarata")
            else:
                sys.stdout.write("|data non dichiarata")



            # 200 TITLE AND STATEMENT OF RESPONSIBILITY
            #   $a	Title Proper
            #   $b	General Material Designation
            titles=statements.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
                if size > 0:
                    title=titles[0].text.encode('utf-8').replace("\n", " ")
                    sys.stdout.write("|"+title)
                else:
                    sys.stdout.write("|titolo non dichiarato")
            else:
                sys.stdout.write("|titolo non dichiarato")



            creators=statements.findall(paths['creators'], namespaces=ns)
            # 700 PERSONAL NAME - PRIMARY RESPONSIBILITY
            #   $a	Entry Element
            if creators is not None:
                size_creators=len(creators)
                if size_creators:
                    sys.stdout.write("|"+creators[0].text.encode('utf-8'))
                    i=1
                    if size_creators > i:
                        while i < size_creators:
                            creator=creators[i].text.encode('utf-8')
                            sys.stdout.write(";"+creator)
                            i+=1
                else:
                    sys.stdout.write("|autore non dichiarato")
            else:
                sys.stdout.write("|autore non dichiarato")

            contributors=statements.findall(paths['contributors'], namespaces=ns)
            contributor_out=0
            if contributors is not None:
                size_contributors=len(contributors)
                if size_contributors:
                    if contributors[0].text is not None:
                        tmp=contributors[0].text.encode('utf-8')
                        s = tmp.replace("\r", "").replace("\n", " ")
                        sys.stdout.write("|"+s)
                        # .replace("\r", "").replace("\n", " ")
                        i=1
                        if size_contributors > i:
                            while i < size_contributors:
                                if contributors[i].text is not None:
                                    contributor= contributors[i].text.encode('utf-8').replace("\r", "").replace("\n", " ")
                                    sys.stdout.write(";"+contributor) # +"\n"
                                    contributor_out += 1
                                i+=1
                    else:
                        if contributor_out == 0:
                            sys.stdout.write("| ")
                else:
                    sys.stdout.write("| ")
            else:
                sys.stdout.write("| ")

            subjects=statements.findall(paths['subjects'], namespaces=ns)
            subject_out=0
            if subjects is not None:
                size=len(subjects)
                i=0
                if size > i:
                    while i < size:
                        # sys.stderr.write(subjects[i].text)
                        subject=subjects[i]
                        if subject.text is not None:
                            subject=subjects[i].text.encode('utf-8').rstrip()
                            if subject_out == 0:
                                sys.stdout.write("|")
                            else:
                                sys.stdout.write(";")
                            sys.stdout.write(subject.replace("\n",""))
                            subject_out += 1
                        else:
                            if subject_out == 0:
                                sys.stdout.write("| ")
                        i+=1
                else:
                    sys.stdout.write("| ")
            else:
                sys.stdout.write("| ")


            # URL of document HANDLE (se presente)
            # handle = 0
            # if identifiers is not None:
            #     size=len(identifiers)
            #     i=0
            #     if size > i:
            #         while i < size:
            #             if identifiers[i].text is not None:
            #                 identifier=identifiers[i].text.encode('utf-8')
            #                 if identifier.startswith('http://hdl.handle.net'):
            #                     sys.stdout.write("|"+identifier)
            #                     handle=1
            #                     break
            #             i+=1
            #     else:
            #         sys.stdout.write("| ")
            # else:
            #     sys.stdout.write("| ")

            sys.stdout.write("|"+jumpoffpageurl)


            # if handle == 0:
            #     sys.stdout.write("|"+diiIdentifier)


            # URL of component resource
            ctr=0;
            found=0
            binary_zero = 0
            components=record.findall(paths['components'], namespaces=ns)
            if components is not None:
                for component in components:
                    if component is not None:
                        resource = component.find(paths['resource'], namespaces=ns)
                        resourceurl = urllib.quote(resource.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")
                        if ctr == 0:
                            sys.stdout.write("|"+resourceurl)
                        else:
                            sys.stdout.write(";;;"+resourceurl)
                            # sys.stdout.write("^")
                            # sys.stdout.buffer.write(bytes([0x00]))
                            # sys.stdout.write("^")
                            # sys.stdout.write(resourceurl)
                        found=1
                    ctr+=1
            if found == 0:
                sys.stdout.write("| ")

            # Scarichiamo l'OAI identifier in caso dobbiamo segnalare mancanti didl:resource
            sys.stdout.write("|"+oaiidentifier)



            rights=statements.findall(paths['rights'], namespaces=ns)
            has_rights=0
            if rights is not None:
                size=len(rights)
                if size > 0:
                    sys.stdout.write("|")
                    if rights[0].text is not None:
                        sys.stdout.write(rights[0].text.encode('utf-8'))
                        has_rights=1

                    i=1;
                    while i < size:
                        if rights[i].text is None:
                            # sys.stdout.write("$adiritti: ") # empty tag
                            i+=1
                            continue
                        if (has_rights == 1):
                            sys.stdout.write(";")
                        sys.stdout.write(rights[i].text.encode('utf-8'))
                        has_rights=1
                        i+=1
                else:
                    sys.stdout.write("| ")
            else:
                sys.stdout.write("| ")


            sys.stdout.write("\n")

out_deleted.close()
