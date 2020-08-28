from io import BytesIO
import pycurl

headers = {}

def display_header(header_line):
    header_line = header_line.decode('iso-8859-1')

    # Ignore all lines without a colon
    if ':' not in header_line:
        return

    # Break the header line into header name and value
    h_name, h_value = header_line.split(':', 1)

    # Remove whitespace that may be present
    h_name = h_name.strip()
    h_value = h_value.strip()
    h_name = h_name.lower() # Convert header names to lowercase
    headers[h_name] = h_value # Header name and value.

def main():
    print('**Using PycURL to get Twitter Headers**')
    b_obj = BytesIO()
    crl = pycurl.Curl()
    crl.setopt(crl.URL, 'https://twitter.com')
    crl.setopt(crl.HEADERFUNCTION, display_header)
    crl.setopt(crl.WRITEDATA, b_obj)
    crl.perform()
    print('Header values:-')
    print(headers)
    print('-' * 20)
    
main()