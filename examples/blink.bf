Blink

Output module required: LED driver
Input module required:  Any

Turns on an LED for approx X clock cycles then off for approx X clock cycles repeatedly

+. Turn on the first LED

[ Main loop
	>++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++< Keep for X clock cycles (more plus = longer)
	-. Turn off the first LED
	>++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++< Keep for X clock cycles
	+. Turn on the first LED
]