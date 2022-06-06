library ieee;
use ieee.std_logic_1164.all;

entity control_logic is

	port (
		clk    : in std_logic;
		instr  : in std_logic_vector(2 downto 0);
		bus_zc : in std_logic;

		lar_up, mar_up, pc_up, alu_up, ram_we, rammult_s0, busmult_s0, busmult_s1, io_s0, io_out : out std_logic; -- active high
		lar_lo, mar_rst, mar_co, pc_lo, pc_co, alu_lo, alu_co, ram_oe                            : out std_logic  -- active low
	);

end control_logic;

architecture RTL of control_logic is
begin

end architecture RTL;