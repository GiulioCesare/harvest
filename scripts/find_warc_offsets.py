# ctrl +alt + m to stop running process
import sys
# Argentino 20/12/2020
# Extract .gz members fro a .gz (for linux generated .gz)


# GZIP Format
# Format
# 	bytes 0-9 header
# 		1f 
# 		8b	Standard GZIP declaration
# 		08	Compression method: 0x08 represents GZIP
# 		08	Flags (see below)
# 		a2 42 b8 4d	Timestamp
# 		00	Extra flags
# 		03	Operating System (3 for linux)
		
# 	last 4 bytes size of uncomressed file (if < 4GB)
# 	- no info on compressed file size within!


import os

CHUNK_SIZE = 4096
SEEK_FROM_START_POS=0
SEEK_FROM_CURRERNT_POS=1
SEEK_FROM_END_POS=1

# extract_n_mebers=0 means all (from starting position)
def extract_members(filename_in, split_dir, from_pos=0, extract_n_members=0):
    members_written=0
    offset=0
    offset_start = -1
    with open(filename_in, "rb") as f_in:
        if (from_pos != 0):
            # check posizion < filesize
            file_in_size = os.path.getsize(filename_in)
            if (from_pos < file_in_size):
                f_in.seek(from_pos, SEEK_FROM_START_POS)
                # print ("Start extracting from " + str(from_pos))
                offset = from_pos

        bytes_read = f_in.read(CHUNK_SIZE)
        print_member = 0
        header_array = bytearray()
        content_array = bytearray()
        file_ctr=0
        # header = 0
        
        stop=0
        while bytes_read:
            for b in bytes_read:

                # if ( len(header_array) == 0 and b == 0x1f ):
                if ( b == 0x1f ):
                    offset += 1
                    if ( len(header_array) == 0):
                        header_array.append(b)
                        # header += 1
                        continue
                    else:
                        # print ("CHECK")
                        if (print_member):
                            f_out.write(header_array)
                        header_array.clear()
                        continue

                if (len(header_array) > 0 ):
                    # header_buf[header]=b
                    header_array.append(b)

                    if (len(header_array) == 2 ):
                        if ( b != 0x8b ):
                            # print(hex(b))
                            # header = 0
                            if (print_member):
                                f_out.write(content_array)
                                content_array.clear()
                                f_out.write(header_array)
                            header_array.clear()
                    elif (len(header_array) == 3 ):
                        if ( b != 0x08 ):
                            if (print_member):
                                f_out.write(content_array)
                                content_array.clear()
                                f_out.write(header_array)
                            header_array.clear()


                    elif (len(header_array) == 10 ):
                        if (b == 0x03):
                            if (print_member != 0):
                                f_out.write(content_array)
                                content_array.clear()
                                f_out.close()
                                members_written += 1
                                print_member = 0

                                if (extract_n_members > 0 and members_written == extract_n_members) :
                                    stop=1
                                    break
                            offset_start = offset - 9

                            # print ("Start export at " + str(offset_start))
                            # if (offset_start == 525645):
                            #     print ("check")

                            file_ctr += 1
                            # filenmae_out = "/home/argentino/tmp/warcs/members/%06d_%012d_%s.gz" % (file_ctr, offset_start, hex(offset_start))
                            filenmae_out = "%s/%06d_%012d_%s.gz" % (split_dir, file_ctr, offset_start, hex(offset_start))


                            # f_out = open("/home/argentino/tmp/warcs/members/"+str(offset_start)+".gz", "wb")
                            f_out = open(filenmae_out, "wb")

                            # f_out.write(header_buf)
                            f_out.write(header_array)
                            header_array.clear()
                            print_member = 1
                        else:
                            # if f_out is not None:
                            if (print_member):
                                f_out.write(content_array)
                                content_array.clear()
                                f_out.write(header_array)
                            header_array.clear()
                    # end elif len == 10
                    offset += 1
                    continue
                    
                # end if (len(header_array) > 0 ):
                offset += 1
                if (print_member):
                    # byte_buf[0]=b
                    # f_out.write(byte_buf)
                    content_array.append(b)
            # end for
            if (stop == 1):
                break
            bytes_read = f_in.read(CHUNK_SIZE)
            
            # end for bytes read
        # end whil
    f_in.close()
    if ( len(content_array) > 0):
        f_out.write(content_array)
    if print_member:    
        f_out.close()
        members_written += 1

    # print ("Members written: " + str(members_written))
    # print ("Last offset start at " + str(offset_start))
    return offset_start
# end extract_members


if (len(sys.argv) < 3):
    print ("usage: warc_filenmae_in, split_dir, block_size")
    exit(1)

warc_filenmae_in = sys.argv[1]
# warc_filenmae_in = '/home/argentino/tmp/warcs/2020_11_11_tesi_lumsa.warc.gz'

split_dir= sys.argv[2]
# /%06d_%012d_%s.gz" % (file_ctr, offset_start, hex(offset_start))

block_size = int (sys.argv[3])
# block_size = 1000000 # Size of gz block we extract from file


# start_from_offset = 17314800    # default 0
# extract_n_members = 1           # default 0 (= all)
# extract_members (filename_gz, start_from_offset, extract_n_members)
# extract_members (filename_gz, extract_n_members=0)

file_in_size = os.path.getsize(warc_filenmae_in)
start_from_offset = block_size
extract_n_members = 1
block_start=0
block_len=0
block_ctr=1
block_total_len=0

print ("# warc_filenmae_in=%s, split_dir=%s, block_size=%d" % (warc_filenmae_in, split_dir, block_size))

while (start_from_offset < file_in_size):
    # print("Find member from =%d" % (start_from_offset))
    extract_offset_start =  extract_members (warc_filenmae_in, split_dir, start_from_offset, extract_n_members)
    # print ("Extract offset start at " + str(extract_offset_start))

    block_end = extract_offset_start-1
    block_len = block_end - block_start + 1
    print ("block_ctr %d block_start %d block_end %d block_len %d" % (block_ctr, block_start, block_end, block_len))
    block_start = extract_offset_start
    start_from_offset = extract_offset_start + block_size
    block_ctr += 1
    block_total_len += block_len
    # break
if (block_end <= file_in_size):
    block_end = file_in_size
    block_len = block_end - block_start # + 1 perche size parte da 1 e non da 0
    block_total_len += block_len
    print ("block_ctr %d block_start %d block_end %d block_len %d" % (block_ctr, block_start, block_end, block_len))

print ("# blocks  total len = %s, file_in_size = %d" %(block_total_len, file_in_size))
    