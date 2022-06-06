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

		phase_out : out std_logic_vector(1 downto 0)
	);

end control_logic;

architecture RTL of control_logic is
	--signal phase: std_logic_vector (1 downto 0) := (others => '0');

	-- Internal Control Signals
	signal phase_rst: std_logic := '0';

	-- Flags
	signal elf, slf: std_logic := '0';
	signal acf: std_logic := '0';

begin
	process (clk, rst) is
		variable phase: std_logic_vector (1 downto 0) := (others => '0');

	begin
		if (rst = '1') then
			phase_rst <= '0';
			phase := (others => '0');
			elf <= '0';
			slf <= '0';
			acf <= '0';
		elsif (falling_edge(clk)) then
			-- On the falling edge, do the things

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


			if phase_rst = '1' then
				phase_rst <= '0';
				phase := (others => '0');
			else
				case phase is
					when "00"   => phase := "01";
					when "01"   => phase := "10"; 
					when "10"   => phase := "11";
					when "11"   => phase := "00"; -- this case should never happen
					when others => assert false report "Invalid phase" severity Error;
				end case;
			end if;
		end if;

		phase_out <= phase;

		if (elf & slf = "00") then
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
					pc_co     <= '0';
					pc_up     <= '1';
					phase_rst <= '1';

				when "101" => -- ']'
					pc_co     <= '0';
					pc_up     <= '1';
					phase_rst <= '1';

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
		elsif (elf & slf = "01") then -- we are looking for the corresponding '[' token
			pc_co     <= '0';
			pc_up     <= '1';
			phase_rst <= '1';
		elsif (elf & slf = "10") then -- we are looking for the corresponding ']' token
			pc_co     <= '0';
			pc_up     <= '1';
			phase_rst <= '1';
		else
			assert false report "Invalid ELF/SLF combination" severity Error;
		end if;
	end process;
end architecture RTL;