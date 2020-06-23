AddressNames({ "lff", "rf", "bzf", "acf", "elf", "slf", "phase1", "phase0", "opcode2", "opcode1", "opcode0" })
ControlSigs({ "FLAGS.SLT", "FLAGS.ELT", "FLAGS.ACT", "FLAGS.BZL", "~PHASE.CO", "PHASE.RESET", "~PC.LO", "~PC.CO", "PC.UP", "~MAR.CO", "MAR.UP", "~LAR.LO", "~LPC.CO", "LPC.UP", "RAMMULT.S0", "RAM.WE", "~RAM.OE", "BUSMULT.S0", "BUSMULT.S1", "~BUSMULT.OE", "~ALU.LO", "~ALU.CO", "ALU.UP", "IO.S0", "IO.OUT" })
InitRom()

Gen({ rf },
function()
	Gen({ n_phase1, n_phase0 }, { LAR.LO, RAM.WE })
	Gen({ n_phase1, phase0 },   { RAMMULT.S0, RAM.WE, MAR.CO, MAR.UP, PC.CO, PC.UP, PHASE.RESET })
end)

Gen({ n_rf },
function()
	Gen({ elf, slf }, { PHASE.RESET }) -- wtf happened.

	Gen({ elf, n_slf }, -- we are looking for the corresponding ']' token
	function()
		-- Here we dont specify phase because every instruction take 1 cycle
		Gen({ opcode2, n_opcode1, n_opcode0 }, { LPC.CO, LPC.UP, PC.CO, PC.UP, PHASE.RESET }) -- we found a new [, we increment the loop counter & fetch
		Gen({ opcode2, n_opcode1, opcode0 }, -- ']': We check if the loop counter is null
		function()
			Gen({ lff },   { RAMMULT.S0, BUSMULT.OE, RAM.WE, FLAGS.ELT, PC.CO, PC.UP, PHASE.RESET }) --> we update the LAR if we found the actual token
			Gen({ n_lff }, { LPC.CO, PC.CO, PC.UP, PHASE.RESET }) --> we decrement the loop counter otherwise
		end)

		-- We fetch every other instruction
		Gen({ n_opcode2, n_opcode1, n_opcode0 }, { PC.CO, PC.UP, PHASE.RESET }) -- +
		Gen({ n_opcode2, n_opcode1, opcode0 },   { PC.CO, PC.UP, PHASE.RESET }) -- -
		Gen({ n_opcode2, opcode1, n_opcode0 },   { PC.CO, PC.UP, PHASE.RESET }) -- >
		Gen({ n_opcode2, opcode1, opcode0 },     { PC.CO, PC.UP, PHASE.RESET }) -- <
		Gen({ opcode2, opcode1, n_opcode0 },     { PC.CO, PC.UP, PHASE.RESET }) -- .
		Gen({ opcode2, opcode1, opcode0 },       { PC.CO, PC.UP, PHASE.RESET }) -- ,
	end)

	Gen({ n_elf, slf }, -- we are looking for the corresponding '[' token
	function()
		-- Here we dont specify phase because every instruction take 1 cycle
		Gen({ opcode2, n_opcode1, opcode0 }, { LPC.CO, LPC.UP, PC.CO, PHASE.RESET }) -- we found a new ], we increment the loop counter & fetch backward
		Gen({ opcode2, n_opcode1, n_opcode0 }, -- '[': We check if the loop counter is null
		function()
			Gen({ lff },   { RAMMULT.S0, BUSMULT.OE, RAM.WE, FLAGS.SLT, PC.CO, PC.UP, PHASE.RESET }) --> we update the LAR if we found the actual token
			Gen({ n_lff }, { LPC.CO, PC.CO, PHASE.RESET }) --> we decrement the loop counter otherwise
		end)

		-- We fetch backward every other instruction
		Gen({ n_opcode2, n_opcode1, n_opcode0 }, { PC.CO, PHASE.RESET }) -- +
		Gen({ n_opcode2, n_opcode1, opcode0 },   { PC.CO, PHASE.RESET }) -- -
		Gen({ n_opcode2, opcode1, n_opcode0 },   { PC.CO, PHASE.RESET }) -- >
		Gen({ n_opcode2, opcode1, opcode0 },     { PC.CO, PHASE.RESET }) -- <
		Gen({ opcode2, opcode1, n_opcode0 },     { PC.CO, PHASE.RESET }) -- .
		Gen({ opcode2, opcode1, opcode0 },       { PC.CO, PHASE.RESET }) -- ,
	end)

	Gen({ n_elf, n_slf },
	function()
		Gen({ n_opcode2, n_opcode1, n_opcode0 },-- +
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ acf },   { ALU.CO, ALU.UP, PC.CO, PC.UP, PHASE.RESET }) -- If the ALU value has already been changed, we just have to increment it
				Gen({ n_acf }, { RAM.OE, ALU.LO }) -- Otherwise, we fetch it, then increment it
			end)
			
			Gen({ n_phase1, phase0, n_acf }, { FLAGS.ACT, ALU.CO, ALU.UP, PC.CO, PC.UP, PHASE.RESET }) -- Phase 1
		end)

		Gen({ n_opcode2, n_opcode1, opcode0 }, -- -
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ acf },   { ALU.CO, PC.CO, PC.UP, PHASE.RESET }) -- If the ALU value has already been changed, we just have to increment it
				Gen({ n_acf }, { RAM.OE, ALU.LO }) -- Otherwise, we fetch it, then increment it
			end)
			
			Gen({ n_phase1, phase0, n_acf }, { FLAGS.ACT, ALU.CO, PHASE.CO, PC.CO, PC.UP, PHASE.RESET }) -- Phase 1
		end)

		Gen({ n_opcode2, opcode1, n_opcode0 }, -- >
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ n_acf }, { MAR.CO, MAR.UP, PC.CO, PC.UP, PHASE.RESET }) -- If the ALU value hasnt been changed, we dont have to update the RAM cell
				Gen({ acf },   { BUSMULT.S1, BUSMULT.OE, RAM.WE })
			end)

			Gen({ n_phase1, phase0, acf }, { FLAGS.ACT, MAR.CO, MAR.UP, PC.CO, PC.UP, PHASE.RESET }) -- Phase 1
		end)

		Gen({ n_opcode2, opcode1, opcode0 }, -- <
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ n_acf }, { MAR.CO, PC.CO, PC.UP, PHASE.RESET }) -- If the ALU value hasnt been changed, we dont have to update the RAM cell
				Gen({ acf },   { BUSMULT.S1, BUSMULT.OE, RAM.WE })
			end)

			Gen({ n_phase1, phase0, acf }, { FLAGS.ACT, MAR.CO, PC.CO, PC.UP, PHASE.RESET }) -- Phase 1
		end)

		Gen({ opcode2, n_opcode1, n_opcode0 }, -- [
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ acf },   { BUSMULT.S1, BUSMULT.OE, FLAGS.BZL, LAR.LO }) -- We check if the ALU value is null and we load PC value into LAR (aka loop cache mem addr)
				Gen({ n_acf }, { RAM.OE, FLAGS.BZL, LAR.LO }) -- Or the RAM cell
			end)

			Gen({ n_phase1, phase0 }, -- Phase 1
			function()
				Gen({ bzf },   { RAMMULT.S0, RAM.OE, FLAGS.BZL }) -- if cell value == 0, we have to skip the loop
				Gen({ n_bzf }, { PC.CO, PC.UP, PHASE.RESET }) -- otherwise, we just enter the loop
			end)

			Gen({ phase1, n_phase0 }, -- Phase 2
			function()
				Gen({ bzf },   { FLAGS.ELT, PC.CO, PC.UP, PHASE.RESET }) -- there's no corresponding bracket stored, we have to find it
				Gen({ n_bzf }, { RAMMULT.S0, RAM.OE, PC.LO, PHASE.RESET }) -- there is: we jump to it
			end)
		end)

		Gen({ opcode2, n_opcode1, opcode0 }, -- ]
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ acf },   { BUSMULT.S1, BUSMULT.OE, FLAGS.BZL, LAR.LO }) -- We check if the ALU value is null and we load PC value into LAR (aka loop cache mem addr)
				Gen({ n_acf }, { RAM.OE, FLAGS.BZL, LAR.LO }) -- Or the RAM cell
			end)

			Gen({ n_phase1, phase0 }, -- Phase 1
			function()
				Gen({ bzf },   { PC.CO, PC.UP, PHASE.RESET }) -- if cell value == 0, we just leave the loop
				Gen({ n_bzf }, { RAMMULT.S0, RAM.OE, FLAGS.BZL }) -- otherwise, we have to skip the loop
			end)

			Gen({ phase1, n_phase0 }, -- Phase 2
			function()
				Gen({ bzf },   { FLAGS.SLT, PC.CO, PHASE.RESET }) -- there's no corresponding bracket stored, we have to find it and we fetch backward
				Gen({ n_bzf }, { RAMMULT.S0, RAM.OE, PC.LO, PHASE.RESET }) -- there is: we jump to it
			end)
		end)

		Gen({ opcode2, opcode1, n_opcode0 }, -- .
		function()
			Gen({ n_phase1, n_phase0 }, -- Phase 0
			function()
				Gen({ acf },   { IO.OUT, PC.CO, PC.UP, PHASE.RESET })
				Gen({ n_acf }, { IO.S0, RAM.OE, IO.OUT, PC.CO, PC.UP, PHASE.RESET })
			end)
		end)

		Gen({ opcode2, opcode1, opcode0 }, -- ,
		function()
			Gen({ n_phase1, n_phase0 },
			function()
				Gen({ acf },   { BUSMULT.S0, BUSMULT.OE, RAM.WE, ALU.LO, PC.CO, PC.UP, PHASE.RESET })
				Gen({ n_acf }, { FLAGS.ACT, BUSMULT.S0, BUSMULT.OE, RAM.WE, ALU.LO, PC.CO, PC.UP, PHASE.RESET })
			end)
		end)
	end)
end)