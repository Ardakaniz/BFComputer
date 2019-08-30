flags = { "rf", "bzf", "acf", "elf", "slf", "lff" }
phase_count = 3
instructions = { "+", "-", ">", "<", "[", "]", ".", "," }

ctrl_addr_org = { FLAGS, PHASE, OPCODE }

ctrl_sigs = {
	"FLAGS.SLT",
	"FLAGS.ELT",
	"FLAGS.ACT",
	"FLAGS.BZL",
	"PHASE.CO",
	"PHASE.RESET",
	"PC.LO",
	"PC.CO",
	"PC.UP",
	"MAR.RESET",
	"MAR.CO",
	"MAR.UP",
	"LAR.LO",
	"LAR.UP",
	"LPC.RESET",
	"LPC.CO",
	"LPC.UP",
	"RAMMULT.S0",
	"RAM.WE",
	"RAM.OE",
	"BUSMULT.S0",
	"BUSMULT.S1",
	"BUSMULT.OE",
	"ALU.LO",
	"ALU.CO",
	"ALU.UP",
	"IO.PA",
	"IO.PB",
}

start_cycle = { "LAR.LO" }
fetch_cycle = { "PHASE.RESET", "PC.CO", "PC.UP" }
phase_inc = { "PHASE.CO" }