#!/usr/bin/env python
# -*- coding: utf-8 -*-


from lxml.etree import parse
from lxml.etree import tostring
import sys
import os
import urllib

filename = sys.argv[1]
istituto = sys.argv[2].lower()

tree = parse(filename)

ns = {
    'didl': 'urn:mpeg:mpeg21:2002:02-DIDL-NS',
    'oai_dc': 'http://www.openarchives.org/OAI/2.0/oai_dc/',
    'dc': 'http://purl.org/dc/elements/1.1/',
    'dii': 'urn:mpeg:mpeg21:2002:01-DII-NS'
}

paths = {
    'oaiidentifier': 'header/identifier',
    'status': 'header[@status]',
    'jumpoffpage': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[1]/didl:Statement/dii:Identifier',
    'dc': 'metadata/didl:DIDL/didl:Item/didl:Descriptor[2]/didl:Statement/',
    'components': 'metadata/didl:DIDL/didl:Item/didl:Component',
    'component': 'didl:Resource'
}

for record in tree.xpath('//record'):

    status = record.find(paths['status'])
    if status is None:

        oaiidentifier = record.find(paths['oaiidentifier']).text

        # if jumpoffpage is a urn transform to an handle http link
        jumpoffpage = record.xpath(paths['jumpoffpage'], namespaces=ns)[0].text
        if "urn" in jumpoffpage:
            jumpoffpageurl = "http://hdl.handle.net/{}".format(jumpoffpage.split(":")[2])
        else:
            jumpoffpageurl = jumpoffpage

        # print jumpoffpageurl

        # 10/01/2021 Fixed access to descriptive page - 
        # Exclude LIUC descriptive page
        # if istituto != "liuc":
        #     print jumpoffpageurl
        print jumpoffpageurl


        for components in record.findall(paths['components'], namespaces=ns):
            component = components.find(paths['component'], namespaces=ns)
            componenturl = urllib.quote(component.get('ref').encode('utf-8'), safe="%/:=&?~#+!$,;'@()*[]")
            print "{}|{}".format(oaiidentifier, componenturl)
            # print "{}".format(componenturl)
