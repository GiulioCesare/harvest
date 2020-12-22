import os
import sys

CHUNK_SIZE = 1024
SEEK_FROM_START_POS = 0
SEEK_FROM_CURRERNT_POS = 1
SEEK_FROM_END_POS = 1



def extract_chunk(filenmae_in, filenmae_out, extract_from_pos, extract_size):
    f_out = open(filenmae_out, "wb")
    f_in = open(filenmae_in, 'rb')
    f_in.seek(extract_from_pos, SEEK_FROM_START_POS)

    cur_chunk_size = CHUNK_SIZE if CHUNK_SIZE < extract_size else extract_size

    extracted_count = 0
    while True:
        chunk = f_in.read(cur_chunk_size)
        if not chunk:
            break
        f_out.write(chunk)
        extracted_count += cur_chunk_size
        cur_chunk_size = CHUNK_SIZE if CHUNK_SIZE + extracted_count < extract_size else extract_size - extracted_count
    f_in.close()
    f_out.close()
# End extract_chunk()


# =====================
# Main
# 
# filenmae_in = "/home/argentino/tmp/warcs/2020_11_11_tesi_lumsa.warc.gz"
# filenmae_out = "/home/argentino/tmp/warcs/block.gz"
# extract_from_pos = 0
# extract_size = 6682-1

# if __name__ == "__main__":
#     print(f"Arguments count: {len(sys.argv)}")
#     for i, arg in enumerate(sys.argv):
#         print(f"Argument {i:>6}: {arg}")

if (len(sys.argv) < 4):
    print ("usage: filenmae_in, filenmae_out, extract_from_pos, extract_size")
    exit(1)
filenmae_in = sys.argv[1]
filenmae_out = sys.argv[2]
extract_from_pos = int(sys.argv[3])
extract_size = int(sys.argv[4])


file_in_size = os.path.getsize(filenmae_in)

if (extract_from_pos > file_in_size):
    print ("extract_from_pos > filesize (%d)" % (file_in_size))
    exit(1)

if (extract_from_pos < 0):
    print ("extract_from_pos cannot be negative %d" % (file_in_size))
    exit(1)

print ("Extracting %s" %(filenmae_out))
extract_chunk(filenmae_in, filenmae_out, extract_from_pos, extract_size)

   