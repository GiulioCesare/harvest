#!/usr/bin/env python
# -*- coding: utf-8 -*-


from lxml.etree import parse
from lxml.etree import tostring
import sys
import os
import urllib
import re

filename = sys.argv[1]
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
    'dc_identifier': 'metadata/oai_dc:dc/dc:identifier',
    'dc_relation': 'metadata/oai_dc:dc/dc:relation'
}

# Dizionario delle URL di un singolo record per scartare eventuali doppioni generati
url_dict={}

for record in tree.xpath('//record'):

    status = record.find(paths['status'])
    # print status
    if status is None:
        url_dict.clear()
        oaiidentifier = record.find(paths['oaiidentifier']).text
        # print oaiidentifier

        for dc_identifier in record.findall(paths['dc_identifier'], namespaces=ns):
            url=dc_identifier.text
            if re.match("^https?://.+$", url) and url not in url_dict:
                # print ("%s|%s" % (oaiidentifier,url))
                print ("%s" % (url))
                url_dict[url]="dummy value"

                # if url di download genera anche il corrispettivo view
                if "article/download" in url:
                    view_url = url.replace("download", "view")
                    print ("%s" % (view_url))
                    url_dict[view_url]="dummy value"

                    view_file_url = url.replace("download", "viewFile")
                    print ("%s" % (view_file_url))
                    url_dict[view_url]="dummy value"



        for dc_relation in record.findall(paths['dc_relation'], namespaces=ns):
            rel_url=dc_relation.text
            if re.match("^https?://.+$", rel_url) and rel_url not in url_dict:
                print ("%s" % (rel_url))
                url_dict[rel_url]="dummy value"

                # if url di view genera anche il corrispettivo download
                if "article/view" in rel_url:
                    rel_download_url = rel_url.replace("view", "download")
                    if rel_download_url not in url_dict:
                        print ("%s" % (rel_download_url))
                        url_dict[rel_download_url]="dummy value"

                    rel_viewfile_url = rel_url.replace("view", "viewFile")
                    if rel_viewfile_url not in url_dict:
                        print ("%s" % (rel_viewfile_url))
                        url_dict[rel_download_url]="dummy value"



        # print(url_dict)
