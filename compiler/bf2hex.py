#!/bin/python3

import sys

def main():
	hex = []

	if len(sys.argv) < 3:
		print("Incorrect arguments")
		return

	input_filename = sys.argv[1]
	output_filename = sys.argv[2]

	with open(input_filename, 'r') as f:
		for line in f:
			for c in line:
				if   c == '+': hex.append(0)
				elif c == '-': hex.append(1)
				elif c == '>': hex.append(2)
				elif c == '<': hex.append(3)
				elif c == '[': hex.append(4)
				elif c == ']': hex.append(5)
				elif c == '.': hex.append(6)
				elif c == ',': hex.append(7)
				elif c == '#': break # Comment

	with open(output_filename, 'wb') as f:
		f.write(bytes(hex))

	with open(output_filename + '.txt', 'w') as f:
		f.write(''.join(map(str, hex)))

if __name__ == '__main__':
	main()