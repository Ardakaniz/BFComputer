+[-,[ # Wait for first input to become != than 0
	>,[,] # Wait for input to become 0 again in order to take it into account
	
	+[-,[ # Wait for second input
	>,[,]
	<< # Go back to A
	[->+<] # Move&Add A to B until A becomes 0 again
	>.     # Print result

	[-]
	# Here the cell is zero we will leave the loops 
	]+]
]+]

+[] # Halts