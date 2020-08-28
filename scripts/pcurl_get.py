# https://stackabuse.com/using-curl-in-python-with-pycurl/

import pycurl
from io import BytesIO 


def check_url(oai_id, search_url, harvest_date, out_file):
	b_obj = BytesIO() 
	crl = pycurl.Curl() 

	# Set URL value
	crl.setopt(crl.URL, 'https://index.depositolegale.it/cdx?url='+search_url)

	# Write bytes that are utf-8 encoded
	crl.setopt(crl.WRITEDATA, b_obj)

	# Perform a file transfer 
	crl.perform() 

	# End curl session
	crl.close()

	# Get the content stored in the BytesIO object (in byte characters) 
	get_body = b_obj.getvalue()

	# Decode the bytes stored in get_body to HTML and print the result 

	# Output of GET request:
	# No Captures found for: http://tesi.depositolegale.it/3115499999
	output=get_body.decode('utf8')

	if output.startswith("No Captures found"):
		# print('%s' % output) # nessuna cattura
		out_file.write(oai_id+"|"+output+"\n")

	else:
		# check per url in harvest date se harvest date specificata
		if  len(harvest_date) > 0 :
			if harvest_date in output:
				# print('Output of GET request:%s' % output) 
				# msg="Url " + search_url + " presente per harvest date " + harvest_date
				# # print msg
				# out_file.write(msg + "\n")
				pass
			else:
				msg = oai_id+"|" + search_url + "| NON PRESENTE per harvest " + harvest_date
				# print msg
				out_file.write(msg + "\n")

		else:
			# msg = "Url " + search_url + " PRESENTE per qualsiasi harvest date"
			# print msg
			# out_file.write(msg + "\n")
			pass

	# end check_url


date="2020_08_05"
# url="http://hdl.handle.net/11584/270677"
# check_url (url, date)


# f = open("seeds_to_check_in_index.txt", "r")
# for url in f:
# 	print(url.rstrip()) 
# 	check_url (url.rstrip(), date)
# f.close()



in_istituti_file = open("istituti.txt", "r")
for ist in in_istituti_file:
	istituto = ist.rstrip()
   	if not istituto:
   		continue

	if istituto[0] == '#':
   		continue


	print("Doing -->"+istituto+"<--") 

	log_file = open("log/"+istituto+".log", "r")
	missing_url_file = open("missing/"+istituto+".mis", "w")
	for line in log_file:
		# print (line.rstrip()) 
		ar = line.split("|")
		oai_id=ar[1]
		url=ar[2].rstrip()
		# print ("oai_id="+oai_id+", url="+url)

		check_url (oai_id, url, date, missing_url_file)

	# break
	missing_url_file.close()
	log_file.close()

	# check_url (url.rstrip(), date)
in_istituti_file.close()
