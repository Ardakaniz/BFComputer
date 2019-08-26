if rf then
	exec({ LAR.LO, RAM.WE })
	exec({ MAR.CO, MAR.UP })
else
	if is_opcode("+") then
		if not acf then
			exec({ RAM.OE, ALU.LO })
		end	
		exec({ ALU.CO, ALU.UP })

	elseif is_opcode("-") then
		if not acf then
			exec({ RAM.OE, ALU.LO })
		end	
		exec({ ALU.CO })

	elseif is_opcode(">") then
		if acf then
			exec({ BUSMULT.OE, RAM.WE })
		end
		exec({ MAR.CO, MAR.UP })
	
	elseif is_opcode("<") then
		if acf then
			exec({ BUSMULT.OE, RAM.WE })
		end
		exec({ MAR.CO })

	elseif is_opcode("[") then
		exec({ RAM.OE, FLAGS.BZL })

		if bzf then -- we skip the loop
			exec({ RAMMULT.S0, RAM.OE, FLAGS.BZL })

			if bzf then -- if there's no corresponding bracket stored, we have to find it

			else -- if there is, we jump to it
				exec_no_fetch({ PC.LO })
			end
		else 
			exec({}) -- we just enter the loop by incrementing the PC
		end

	elseif is_opcode("]") then

	elseif is_opcode(".") then

	elseif is_opcode(",") then

	end
end