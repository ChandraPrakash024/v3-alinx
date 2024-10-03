# Python code to generate in_eth testing packets - This is to be repeated for each ethernet port
import json
import random
import argparse
from array import array
import os

accept_rules = []
reject_rules = []

# Read rules from the rules file
def read_rules(rules_file):
	rfile_handle = open(rules_file,"r")
	rules = json.load(rfile_handle)["rules"]

	for rule in rules:
		action_type = rule.pop('action')
		if action_type == "ACCEPT":
			accept_rules.append(rule)
		else:
			reject_rules.append(rule)

# Generate safe headers
def safe_header_generator(n):	

	print(f"Number of SAFE headers to be generated: {n}")
	if (n == 0): return []	
	# if (len(accept_rules) < n): n = len(accept_rules)
	# print(f"Number of SAFE headers generated: {n}")

	safe_headers = random.choices(accept_rules, k=n)
	return safe_headers

# Generate unsafe headers
def unsafe_header_generator(n):

	print(f"Number of UNSAFE headers to be generated: {n}")
	if (n == 0): return []	
	# if (len(reject_rules) < n): n = len(reject_rules)
	# print(f"Number of UNSAFE headers generated: {n}")

	unsafe_headers = random.choices(reject_rules, k=n)
	return unsafe_headers


# Generate random headers
def random_header_generator(n):

	print(f"Number of RANDOM headers to be generated: {n}")

	rand_headers = []
	for _ in range(n):
		src_ip = ".".join(str(random.randint(0, 255)) for _ in range(4))
		dst_ip = ".".join(str(random.randint(0, 255)) for _ in range(4))
		protocol = str(random.randint(0, 255))
		src_port = str(random.randint(0, 65535))
		dst_port = str(random.randint(0, 65535))

		new_header = {
			'src_ip': src_ip,
			'dst_ip': dst_ip,
			'protocol': protocol,
			'src_port_min': src_port,
			'src_port_max': src_port,
			'dst_port_min': dst_port,
			'dst_port_max': dst_port
		}
		rand_headers.append(new_header)

	return rand_headers


# Generate random packet based on given header
def packet_generator(header): 

	payload_size = FrameSize
	data_size = bytearray(payload_size.to_bytes(2, 'big'))
	data_size = data_size[0:2] # take 2 bytes
	data_size_array = array('B', data_size)

	# Generating a random packet
	rand_packet = random.randint(0, (1 << (FrameSize * 8)) - 1)
	byte_str = rand_packet.to_bytes(FrameSize, 'big')
	byte_array = bytearray(byte_str)#, byteorder='big')
	
	# Giving correct protocol, IP and port addresses
	for i in range(26): byte_array[i] =  0xFF
	byte_array[23] = int(header['protocol'])
	byte_array[26:30] = [int(c) for c in header['src_ip'].split('.')]
	byte_array[30:34] = [int(c) for c in header['dst_ip'].split('.')]
	src_port = random.randint(int(header['src_port_min']) , int(header['src_port_max']))
	dst_port = random.randint(int(header['dst_port_min']) , int(header['dst_port_max']))
	byte_array[34:36] = bytearray(src_port.to_bytes(2, 'big'))
	byte_array[36:38] = bytearray(dst_port.to_bytes(2, 'big'))
	byte_array_as_array = array('B', byte_array)  # Create array.array with byte elements

	# Attaching size of the frame to the front
	mod_packet = int.from_bytes(data_size_array + byte_array_as_array, 'big')
	hex_string = '{:x}'.format(mod_packet)
	while len(hex_string) < FrameSize*2+4: # Size of len is 16bits
		hex_string = "0"+hex_string

	return hex_string




if __name__ == "__main__":
	
	parser = argparse.ArgumentParser(description="Process arguments for packet generation")
	
	parser.add_argument("--rules", help="Location of the rules file")
	parser.add_argument("--feeds", help="Location of the packet feed folder")
	parser.add_argument("--num_safe", type=int, default=0, help="Number of safe packets")
	parser.add_argument("--num_unsafe", type=int, default=0, help="Number of unsafe packets")
	parser.add_argument("--num_random", type=int, default=0, help="Number of random packets")
	parser.add_argument("--FrameSize", type=int, default=0, help="Frame size")
	parser.add_argument("--EthID", type=int, default=0, help="Ethernet ID")
	parser.add_argument("--iter", type=int, default=1, help="Number of iterations of packets")

	args = parser.parse_args()
	FrameSize = args.FrameSize
	EthID = args.EthID
	
	read_rules(args.rules)

	all_headers = []
	all_headers.extend(safe_header_generator(args.num_safe))
	all_headers.extend(unsafe_header_generator(args.num_unsafe))
	all_headers.extend(random_header_generator(args.num_random))

	iterations = int(args.iter)
	all_headers = all_headers*iterations
	random.shuffle(all_headers)

	## write packet into file
	assert os.path.exists(args.feeds), "Packet feed folder doesn't exist"
	in_file = args.feeds + "/in_eth" + str(EthID) + ".txt"
	fh = open(in_file, "w")

	for l in range(len(all_headers)):
		header = all_headers[l]
		pkt = packet_generator(header)
		fh.write(pkt)
		if l != len(all_headers)-1:
			fh.write("\n")

print("Packet generation completed")
