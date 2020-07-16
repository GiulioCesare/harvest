#!/usr/bin/env python
# -*- coding: utf-8 -*-

# 16/09/2019
# Mapping table Dublin core/Unimarc at:
#   https://docs.google.com/spreadsheets/d/1EXCAiCwhG6JevRonMv62luJjL0OQ-7r6n7pnOyaDGHw/edit#gid=1153896167

from lxml import etree
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

# l= len(sys.argv);
# sys.stderr.write(str(l))

if (len(sys.argv) < 2):
    print ("parse_tesi_embargo istituto_metadata.xml")
    sys.exit(0)


metadati_filename = sys.argv[1]

tree = parse(metadati_filename)


# print etree.tostring(tree)
# sys.exit(0)



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

    'statements': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[2]/didl:Statement/',    # tutti gli statements del secondo descriptor

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

    'resource': 'didl:Resource',

    'component_descriptor' : 'didl:Descriptor',

    'component_descriptor_rights' : 'didl:Statement/oai_dc:dc/dc:rights',
    'component_descriptor_date' : 'didl:Statement/oai_dc:dc/dc:date'

}

recs=int(0)

sys.stdout.write("#oaiidentifier|RIGHTS|Data fine embargo|URL (pg descrittiva)|title\n") #|creators|contributors


for record in tree.xpath('.//record'): # Selects all subelements, on all levels beneath the current element. For example, .//egg selects all egg elements in the entire tree.
    recs += 1
    if recs > 1:
        print ("") # riga di separazione tra record
    # print "--> record # "+str(recs)

    status = record.find(paths['status'])
    # print "status="+str(status)


    if status is None:

        oaiidentifier = record.find(paths['oaiidentifier']).text
        # sys.stdout.write(oaiidentifier+"|")

        TESI="";
        for statements in record.findall(paths['statements'], namespaces=ns):

            rights=statements.findall(paths['rights'], namespaces=ns)
            R="";
            global_embargo=0
            if rights is not None:
                size=len(rights)
                if size > 0:
                    i=0;
                    written_first=0
                    while i < size:
                        if rights[i].text is None:
                            # sys.stdout.write("$adiritti: ") # empty tag
                            i+=1
                            continue
                        # if written_first > 0:
                        #     r = ";"+rights[i].text.encode('utf-8');    
                        # else:
                        #     r = rights[i].text.encode('utf-8');    
                        # sys.stdout.write(r)
                        # R += r
                        # written_first=1
                        # i+=1

                        # Assume we only ha 1 dc:rights declaration
                        R = rights[i].text.encode('utf-8');

                        # controlla se sotto embargo
                        u_R = R.upper()
                        if (re.search('EMBARGO', u_R )):
                            global_embargo=1
                        # print "u_R="+u_R + "global_embargo="+str(global_embargo)
                        break 




            # sys.stdout.write("|")
            global_embargo_end_date=""
            dates=statements.findall(paths['dates'], namespaces=ns)
            if dates is not None:
                dates_len= len(dates)
                if (dates_len > 0):
                    i=0;
                    while i < dates_len:
                        if dates[i].text is None:
                            # sys.stdout.write("$adiritti: ") # empty tag
                            i+=1
                            continue
                        date=dates[i].text.encode('utf-8')
                        u_date = date.upper()

                        if (re.search('EMBARGOEND', u_date)):
                            # if ( i > 0):
                            #     sys.stdout.write(";")
                            # sys.stdout.write(u_date)
                            global_embargo_end_date = u_date.rsplit('/', 1)[1]; # get the date
                            # sys.stdout.write(global_embargo_end_date) 
                            break
                        i+=1





            jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
            if "urn" in jumpoffpage:
                jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
            else:
                jumpoffpageurl = jumpoffpage

            JOP = jumpoffpageurl

            # sys.stdout.write(j)



            titles=statements.findall(paths['titles'], namespaces=ns)
            if titles is not None:
                size=len(titles)
                if size > 0:
                    title=titles[0].text.encode('utf-8')
                    title_r=title.replace("\n", " ")
                    # sys.stdout.write("|"+title_r)
                    TESI += title_r




            # URL of resource
            components=record.findall(paths['components'], namespaces=ns)
            COMP=""
            embargoed_component=0;
            for component in components:
                if component is not None:

                    # print etree.tostring(component)

                    resource = component.find(paths['resource'], namespaces=ns)

                    # print etree.tostring(resource)

                    resourceurl = urllib.quote(resource.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")


                    if global_embargo == 1: 
                        # Tesi  sotto emabargo a livello globale
                        COMP += "\n" + oaiidentifier+"|" +R  + "|" + global_embargo_end_date +"|" +resourceurl + "|" + TESI 
                        continue

                    component_descriptor=component.find(paths['component_descriptor'], namespaces=ns)
                    # print etree.tostring(component_descriptor)
                    comp_embargo_end_date=""
                    if component_descriptor is not None:

                        # Tesi NON sotto emabargo a livello globale
                        # Abbiamo dei diritti nel componente?
                        rights_comp=component_descriptor.find(paths['component_descriptor_rights'], namespaces=ns)
                        date_comp=component_descriptor.find(paths['component_descriptor_date'], namespaces=ns)

                        r_cmp="";
                        if rights_comp is not None:
                            r_cmp = rights_comp.text.encode('utf-8')

                        # sys.stdout.write("\nr_cmp='"+r_cmp+"'")


                        if not r_cmp:
                            # sys.stdout.write(oaiidentifier+"|" +R + "|" + embargo_end_date  +"|" +resourceurl + "|" + tesi)    # diritti derivati dalla tesi nel suo insieme
                            COMP += "\n" + oaiidentifier+"|" +"accesso libero" + "|" + comp_embargo_end_date  +"|" +resourceurl + "|" + TESI

                        else:
                            # sys.stdout.write(oaiidentifier+"|" +r_cmp  + "|" + embargo_end_date +"|"+resourceurl +"|" + tesi ) # diritti del componente
                            u_r_cmp = r_cmp.upper()
                            if (re.search('EMBARGO', u_r_cmp)):
                                embargoed_component=1
                                # comp_embargo_end_date="8888"
                                if date_comp is not None:
                                    # comp_embargo_end_date="7777"
                                    date=date_comp.text.encode('utf-8')
                                    # comp_embargo_end_date=date
                                    u_date = date.upper()
                                    # comp_embargo_end_date=u_date
                                    if (re.search('EMBARGOEND', u_date)):
                                        comp_embargo_end_date = u_date.rsplit('/', 1)[1]; # get the date

                                COMP += "\n" + oaiidentifier+"|" +r_cmp  + "|" + comp_embargo_end_date +"|"+resourceurl +"|" + TESI

                    else: 
                        # nessun descriptor con o senza rights. Mettiamo i rights della pagina descrittiva 
                        # sys.stdout.write(oaiidentifier+"|" +R  + "|" + embargo_end_date +"|" +resourceurl + "|" + tesi  )   # diritti derivati dalla tesi nel suo insieme
                        COMP += "\n" + oaiidentifier+"|" +"accesso libero"  + "|" + comp_embargo_end_date +"|" +resourceurl + "|" + TESI 

            r = R.upper()
            # print r
            if ((re.search('PARTIALLY_OPEN', r) or re.search('RESTRICTEDACCESS', r))  and embargoed_component == 0): #  
                R += " (messa sotto embargo)"
                COMP = COMP.replace("accesso libero", R)


            sys.stdout.write(oaiidentifier+"|" +R +"|" +global_embargo_end_date +"|" +JOP +"|" +TESI )
            if COMP != "":
                sys.stdout.write(COMP +"+")
