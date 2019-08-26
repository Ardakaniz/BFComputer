flags = { "slf", "elf", "acf", "bzh", "rf", "lff", "bzf" }
phase_count = 3
instructions = { "+", "-", ">", "<", "[", "]", ".", "," }

ctrl_addr_org = { FLAGS, PHASE, OPCODE }

ctrl_sigs = {
	"ALU.LO",
	"ALU.CO",
	"ALU.UP",
	"PHASE.CO",
	"PHASE.RESET",
	"PC.CO",
	"PC.UP",
	"LAR.LO",
	"MAR.CO",
	"MAR.UP",
	"RAM.OE",
	"RAM.WE",
}

start_cycle = { "LAR.LO" }
fetch_cylce = { "PHASE.RESET", "PC.CO", "PC.UP" }
phase_inc = { "PHASE.CO" }