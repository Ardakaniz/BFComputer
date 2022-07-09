library ieee;
use ieee.std_logic_1164.all;

entity control_logic is

	port (
		clk, rst : in std_logic;
		instr    : in std_logic_vector(2 downto 0);
		bus_zc   : in std_logic;

		lar_up, mar_up, pc_up, alu_up, ram_we, rammult_s0, busmult_s0, busmult_s1, io_s0, io_out
		: out std_logic := '0'; -- active high

		lar_lo, mar_co, pc_lo, pc_co, alu_lo, alu_co, ram_oe, busmult_oe
		: out std_logic  := '1'; -- active low

		elf_sig : out std_logic := '0'
	);

end control_logic;

architecture RTL of control_logic is
	use ieee.numeric_std.all;

	--signal phase: std_logic_vector (1 downto 0) := (others => '0');

	-- Internal Control Signals
	signal phase_rst: std_logic := '0';

	-- Flags
	signal elf, slf: std_logic := '0';
	signal acf, bzf: std_logic := '0';

	constant MAX_VALUE: integer := (2**12) - 1;
	signal lpc : integer range 0 to MAX_VALUE;

begin
	process (clk, rst) is
		variable phase: std_logic_vector (1 downto 0) := (others => '0');

	begin
		-- ugly
		lar_up     <= '0';
		mar_up     <= '0';
		pc_up      <= '0';
		alu_up     <= '0';
		ram_we     <= '0';
		rammult_s0 <= '0';
		busmult_s0 <= '0';
		busmult_s1 <= '0';
		io_s0      <= '0';
		io_out     <= '0';

		lar_lo <= '1';
		mar_co <= '1';
		pc_lo  <= '1';
		pc_co  <= '1';
		alu_lo <= '1';
		alu_co <= '1';
		ram_oe <= '1';
		busmult_oe <= '1';

	
		if (rst = '1') then
			phase_rst <= '0';
			phase := (others => '0');
			elf <= '0';
			slf <= '0';
			acf <= '0';
			lpc <= 0;

			pc_lo <= '0';

		else
			if (falling_edge(clk)) then
				-- On the falling edge, do the things

				if phase_rst = '1' then
					phase_rst <= '0';
					phase := (others => '0');
				else
					case phase is
						when "00"   => phase := "01";
						when "01"   => phase := "10"; 
						when "10"   => phase := "11";
						--when "11"   => phase := "00"; -- this case should never happen
						when others => assert false report "Invalid phase" severity Error;
					end case;
				end if;
			end if;

			if (elf = '0' and slf = '0') then -- Normal instruction
				case instr is
					when "000" => -- '+'
						if acf = '1' then
							alu_co    <= '0';
							alu_up    <= '1';
							pc_co     <= '0';
							pc_up     <= '1';
							phase_rst <= '1';
						else
							if phase = "00" then
								ram_oe <= '0';
								alu_lo <= '0';
							elsif phase = "01" then
								acf       <= '1';
								alu_co    <= '0';
								alu_up    <= '1';
								pc_co     <= '0';
								pc_up     <= '1';
								phase_rst <= '1';
							end if;
						end if;
	
					when "001" => -- '-'
						if acf = '1' then
							alu_co    <= '0';
							pc_co     <= '0';
							pc_up     <= '1';
							phase_rst <= '1';
						else
							if phase = "00" then
								ram_oe <= '0';
								alu_lo <= '0';
							elsif phase = "01" then
								acf       <= '1';
								alu_co    <= '0';
								pc_co     <= '0';
								pc_up     <= '1';
								phase_rst <= '1';
							end if;
						end if;
	
					when "010" => -- '>'
						if acf = '1' then
							if phase = "00" then
								busmult_s1 <= '1';
								busmult_oe <= '0';
								ram_we <= '1';
							elsif phase = "01" then
								acf       <= '0';
								mar_co    <= '0';
								mar_up    <= '1';
								pc_co     <= '0';
								pc_up     <= '1';
								phase_rst <= '1';
							end if;
						else
							mar_co    <= '0';
							mar_up    <= '1';
							pc_co     <= '0';
							pc_up     <= '1';
							phase_rst <= '1';
						end if;
	
					when "011" => -- '<'
						if acf = '1' then
							if phase = "00" then
								busmult_s1 <= '1';
								busmult_oe <= '0';
								ram_we <= '1';
							elsif phase = "01" then
								acf       <= '0';
								mar_co    <= '0';
								pc_co     <= '0';
								pc_up     <= '1';
								phase_rst <= '1';
							end if;
						else
							mar_co    <= '0';
							pc_co     <= '0';
							pc_up     <= '1';
							phase_rst <= '1';
						end if;
	
					when "100" => -- '['
						case phase is
							when "00" => 
								if acf = '1' then -- If the ALU value has been changed
									busmult_s1 <= '1';
									busmult_oe <= '0'; -- we load it onto the BUS
									--ram_we     <= '1'; its value in ram will be changed afterward
								else             -- Otherwise, we load RAM value onto BUS
									ram_oe     <= '0';
								end if;

								bzf    <= bus_zc; -- We update the BusZeroFlag
								lar_lo <= '0';    -- and load LAR with PC val

							when "01" =>
								if bzf = '1' then -- If the cell_value == 0, we have to skip loop
									rammult_s0 <= '1';    -- Therefore, we load Loop RAM onto BUS
									ram_oe		 <= '0';
									bzf        <= bus_zc; -- And update the BZF
								else             -- otherwise, we just enter the loop
									pc_co     <= '0';
									pc_up     <= '1';
									phase_rst <= '1';
								end if;

							-- HERE: only if cell_value == 0
							when "10" =>
								if bzf = '1' then -- If the Loop RAM is null
									elf       <= '1'; -- We have to search for the 'End of the Loop'
									pc_co     <= '0';
									pc_up     <= '1';
								else             -- Otherwise, it contains the End of the Loop address
									rammult_s0 <= '1';
									ram_oe		 <= '0'; -- So we load Loop RAM onto BUS
									pc_lo 	   <= '0'; -- And load the PC to this value
								end if;

								phase_rst <= '1';

							when others => assert false report "unexpected phase" severity error;
						end case;
	
					when "101" => -- ']'
						case phase is
							when "00" => 
								if acf = '1' then -- If the ALU value has been changed
									busmult_s1 <= '1';
									busmult_oe <= '0'; -- we load it onto the BUS
									--ram_we     <= '1'; its value in ram will be changed afterward
								else              -- Otherwise, we load RAM value onto BUS
									ram_oe <= '0';
								end if;

								bzf    <= bus_zc; -- We update the BusZeroFlag
								lar_lo <= '0';    -- and load LAR with PC val

							when "01" =>
								if bzf = '1' then -- If the cell_value == 0, we leave the loop
									pc_co     <= '0';
									pc_up     <= '1';
									phase_rst <= '1';
								else              -- otherwise, we have to go back to the beginning
									rammult_s0 <= '1';    -- Therefore, we load Loop RAM onto BUS
									ram_oe		 <= '0';
									bzf        <= bus_zc; -- And update the BZF
								end if;

							-- HERE: only if cell_value != 0
							when "10" =>
								if bzf = '1' then -- If the Loop RAM is null
									slf       <= '1'; -- We have to search for the 'Start of the Loop'
									pc_co     <= '0'; -- So we count back now
								else             -- Otherwise, it contains the End of the Loop address
									rammult_s0 <= '1';
									ram_oe		 <= '0'; -- So we load Loop RAM onto BUS
									pc_lo 	   <= '0'; -- And load the PC to this value
								end if;

								phase_rst  <= '1';

							when others => assert false report "unexpected phase" severity error;
						end case;
	
					when "110" => -- '.'
						if acf = '0' then
							io_s0  <= '1';
							ram_oe <= '0';
						end if;
	
						io_out    <= '1';
						pc_co     <= '0';
						pc_up     <= '1';
						phase_rst <= '1';
	
					when "111" => -- ','
						acf        <= '1';
						busmult_oe <= '0';
						ram_we     <= '1';
						alu_lo     <= '0';
						pc_co      <= '0';
						pc_up      <= '1';
						phase_rst  <= '1';
	
					when others =>
						assert false report "Invalid instruction" severity Error;
				end case;
			elsif (elf = '0' and slf = '1') then -- we are looking for the corresponding '[' token
				if instr = "100" then -- '['
					if (lpc = 1) then -- If we did find the token
						rammult_s0 <= '1';
						busmult_oe <= '0'; -- Output
						busmult_s0 <= '1'; -- PC
						ram_we     <= '1';
						slf        <= '0';
						pc_up      <= '1';	
						lpc        <= 0;
					else               -- else write the corresponding address into Loop RAM
						lpc <= lpc - 1;  -- then decrement the counter
					end if;
				elsif instr = "101" then -- ']'
						lpc <= lpc + 1;
				end if;

				pc_co     <= '0';
				phase_rst <= '1';
			elsif (elf = '1' and slf = '0') then -- we are looking for the corresponding ']' token
				if instr = "100" then    -- '['
					lpc   <= lpc + 1;
				elsif instr = "101" then -- ']'
					if not (lpc = 1) then -- If we didnt find the token yet
						lpc <= lpc - 1;     -- then continue searching
					else                  -- else write the corresponding address into Loop RAM
						rammult_s0 <= '1';
						busmult_oe <= '0';
						busmult_s0 <= '1';
						ram_we		 <= '1';
						elf 			 <= '0';
						lpc        <= 0;
					end if;
				end if;

				pc_co     <= '0';
				pc_up     <= '1';
				phase_rst <= '1';
			else
				assert false report "Invalid ELF/SLF combination" severity Error;
			end if;
		end if;
	end process;
end architecture RTL;