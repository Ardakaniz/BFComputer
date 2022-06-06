library ieee;
use ieee.std_logic_1164.all;

-- 74169 chip

entity reg is

port (
	CLK : in std_logic;
	LO  : in std_logic; -- active low
	UP	: in std_logic;
	CO  : in std_logic; -- active low

	i  : in  std_logic_vector(11 downto 0);
	o : out std_logic_vector(11 downto 0)
);

end entity reg;

architecture RTL of reg is
	use ieee.numeric_std.all;

	constant MAX_VALUE: integer := (2**o'length) - 1;
	signal output_sig : integer range 0 to MAX_VALUE;

begin
	process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (LO = '0') then
				output_sig <= to_integer(unsigned(i));
			elsif (CO = '0') then
				if (UP = '1') then
					if (output_sig = MAX_VALUE) then
						output_sig <= 0;
					else
						output_sig <= output_sig + 1;
					end if;
				else
					if (output_sig = 0) then
						output_sig <= MAX_VALUE;
					else
						output_sig <= output_sig - 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	o <= std_logic_vector(to_unsigned(output_sig, o'length));
end architecture RTL;