library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zero_checker is
	generic (
		WIDTH: positive := 12
	);

	port (
		i: in std_logic_vector(WIDTH-1 downto 0);
		o: out std_logic
	);
end entity zero_checker;

architecture RTL of zero_checker is
begin
	process (i)
		variable intermediate: std_logic_vector(WIDTH-1 downto 0);
	begin
		intermediate(0) := i(0);

		for idx in 1 to WIDTH-1 loop
			intermediate(idx) := i(idx) or intermediate(idx-1);
		end loop;

		o <= not intermediate(WIDTH-1);

	end process;

end architecture RTL;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zero_checker_tb is
end entity zero_checker_tb;

architecture behav of zero_checker_tb is
	component zero_checker
		generic (
			WIDTH: integer
		);

		port (
			i: in std_logic_vector(11 downto 0);
			o: out std_logic
		);
	end component;

	signal i: std_logic_vector(11 downto 0);
	signal o: std_logic;
begin

	checker: zero_checker 
		generic map (WIDTH => 12)
		port map (i => i, o => o);

	process
	begin

		i <= (others => '0');
		wait for 1 ns;
		assert o = '1' report "Zero checked" severity error;

		for n in 1 to (2**12) - 1 loop
			i <= std_logic_vector(to_unsigned(n, 12));
			wait for 1 ns;
			assert o = '0' report "Non zero not checked" severity error;
		end loop;

		assert false report "Test OK" severity note;
		
		wait;
	end process;

end architecture behav;
