Caterpillar

Output module required: LED driver
Input module required:  Any

Turns on an the first LED for approx X clock cycles then off the first one but on the second one for approx X clock cycles and so on

+. Turn on the first LED

[ Main loop
	[
		>++++++++++----------< Keep for X clock cycles
		[->+>+<<]>[-<+>]>[-<<+>>]<<. Double the cell value to now drive to next LED
	]

	+. If the cell value ends up to be null (happens when we drove all the LEDs) we just directly turns the first LED and loop
]