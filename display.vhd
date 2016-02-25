library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity display is
	port (
		segments_n : in  std_logic;
		digits_n   : in  std_logic;
		rst        : in  std_logic;
		data       : in  std_logic_vector(7 downto 0);
		
		segments   : out std_logic_vector(7 downto 0);
		COUNTEN    : out std_logic;
		DIGSEL     : out std_logic_vector(2 downto 0)
	);
end display;

architecture arch of display is
	signal seg_reg   : std_logic_vector(7 downto 0) := (others => '0');
	signal dig_reg   : std_logic_vector(2 downto 0) := (others => '0');
	signal count_reg : std_logic; 
	
begin
	segments <= seg_reg when (rst = '0') else
			"ZZZZZZZZ";		

	DIGSEL <= dig_reg when (rst = '0') else
			"ZZZ";		

	COUNTEN <= count_reg when (rst = '0') else
			'Z';		

	latch1 : process(segments_n) is
	begin
		if (segments_n = '1') then
			seg_reg <= data;
		end if;
	end process;

	latch2 : process(digits_n) is
	begin
		if (digits_n = '1') then
			count_reg <= data(4);
			dig_reg <= data(7 downto 5);
		end if;
	end process;
end;