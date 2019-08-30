if rf then
	exec({ LAR.LO, RAM.WE })
	exec({ MAR.CO, MAR.UP })
elseif els then
	if is_opcode("[") then
		exec({ LPC.CO, LPC.UP }) -- we increment the loop counter
	elseif is_opcode("]") then
		exec({ LPC.CO }) -- we decrement the loop counter and we check if it is null
		if lff then
			-- if it is, we found the end loop token
			exec({ LAR.LO })
			exec({ RAMMULT.S0, BUSMULT.S0, BUSMULT.OE, RAM.WE, FLAGS.ELT }) -- we load the current instruction index (PC content) into the cache loop ram memory (indexed by the LAR) and tell the computer we found it
		else
			exec({}) -- if not, we dont do anything else than incrementing the program counter
		end
	else
		exec({}) -- if it is any other instruction, we just skip it
	end
elseif sls then -- there, we have to read the instructions backward because the start of a loop can only be before the end
	if is_opcode("[") then
		exec({ LPC.CO }) -- we decrement the loop counter and we check if it is null
		if lff then
			-- if it is, we found the end loop token
			exec({ LAR.LO })
			exec({ RAMMULT.S0, BUSMULT.S0, BUSMULT.OE, RAM.WE, FLAGS.SLT }) -- we load the current instruction index (PC content) into the cache loop ram memory (indexed by the LAR) and tell the computer we found it
		else
			exec_no_fetch({ PC.CO, PHASE.RESET }) -- if not, we dont do anything else than decrementing the program counter
		end
	elseif is_opcode("]") then
		exec_no_fetch({ LPC.CO, LPC.UP, PC.CO, PHASE.RESET }) -- we increment the loop counter and decrement the program counter
	else
		exec_no_fetch({ PC.CO, PHASE.RESET }) -- if it is any other instruction, we just skip it
	end
else
	if is_opcode("+") then
		if not acf then
			exec({ RAM.OE, ALU.LO, FLAGS.ACT })
		end	
		exec({ ALU.CO, ALU.UP })

	elseif is_opcode("-") then
		if not acf then
			exec({ RAM.OE, ALU.LO, FLAGS.ACT })
		end	
		exec({ ALU.CO })

	elseif is_opcode(">") then
		if acf then
			exec({ BUSMULT.OE, RAM.WE, FLAGS.ACT })
		end
		exec({ MAR.CO, MAR.UP })
	
	elseif is_opcode("<") then
		if acf then
			exec({ BUSMULT.OE, RAM.WE, FLAGS.ACT })
		end
		exec({ MAR.CO })

	elseif is_opcode("[") then
		exec({ RAM.OE, FLAGS.BZL, LAR.LO })

		if bzf then -- we skip the loop if ram value == 0
			exec({ RAMMULT.S0, RAM.OE, FLAGS.BZL })

			check_flag("bzf",
			function() -- if there's no corresponding bracket stored, we have to find it
				exec_no_fetch({ FLAGS.ELT, PHASE.RESET }) -- we tell the computer that we are looking for the corresponding ']'
			end,
			function() -- if there is, we jump to it
				exec_no_fetch({ RAM.OE, PC.LO, PHASE.RESET })
			end)
		else 
			exec({}) -- we just enter the loop by incrementing the PC
		end

	elseif is_opcode("]") then
		exec({ RAM.OE, FLAGS.BZL, LAR.LO })

		if bzf then -- we leave the loop if ram value != 0
			exec({})
		else -- otherwise, we look for the corresponding bracket
			exec({ RAMMULT.S0, RAM.OE, FLAGS.BZL })

			check_flag("bzf",
			function() -- if there's no corresponding bracket stored, we have to find it
				exec_no_fetch({ FLAGS.SLT, PHASE.RESET }) -- we tell the computer that we are looking for the corresponding '['
			end,
			function() -- if there is, we jump to it
				exec_no_fetch({ RAM.OE, PC.LO, PHASE.RESET })
			end)
		end

	elseif is_opcode(".") then
		if acf then
			exec({ IO.PA })
		else
			exec({ IO.PB })
		end

	elseif is_opcode(",") then
		exec({ BUSMULT.S1, BUSMULT.OE, RAM.WE })
	end
end