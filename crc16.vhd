library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity crc16 is
	port (
		clk      : in  std_logic;
		data     : in  std_logic;
		rst      : in  std_logic;
		crc      : out std_logic_vector(15 downto 0)
	);
end crc16;

architecture arch of crc16 is
	signal curcrc : std_logic_vector(15 downto 0) := (others => '0');
	signal newcrc : std_logic_vector(15 downto 0) := (others => '0');
begin
	crc <= curcrc;
	
	newcrc(0) <= (((curcrc(6) xor curcrc(8)) xor curcrc(11)) xor curcrc(15)) xor data;
	newcrc(1)  <= curcrc(0);
	newcrc(2)  <= curcrc(1);
	newcrc(3)  <= curcrc(2);
	newcrc(4)  <= curcrc(3);
	newcrc(5)  <= curcrc(4);
	newcrc(6)  <= curcrc(5);
	newcrc(7)  <= curcrc(6);
	newcrc(8)  <= curcrc(7);
	newcrc(9)  <= curcrc(8);
	newcrc(10) <= curcrc(9);
	newcrc(11) <= curcrc(10);
	newcrc(12) <= curcrc(11);
	newcrc(13) <= curcrc(12);
	newcrc(14) <= curcrc(13);
	newcrc(15) <= curcrc(14);
	
	process(clk, rst) begin
		if (rst = '0') then
			curcrc <= (others => '0');
		elsif (falling_edge(clk)) then
			curcrc <= newcrc;
		end if;
	end process;
end arch;