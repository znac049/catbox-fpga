library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sig16 is
	port (
		clk      : in  std_logic;
		data     : in  std_logic;
		rst      : in  std_logic;
		run_stop : in  std_logic;
		sig      : out std_logic_vector(15 downto 0)
	);
end sig16;

architecture arch of sig16 is
	component crc16 is
		port (
			clk      : in  std_logic;
			data     : in  std_logic;
			rst      : in  std_logic;
			crc      : out std_logic_vector(15 downto 0)
		);
	end component;

	signal data_line : std_logic;	
begin
	crc_gen : crc16 port map(
		clk => clk,
		data => data_line,
		rst => rst,
		crc => sig
	);

	process(clk, rst) begin
		if (rst = '0') then
			data_line <= '1';
		elsif (run_stop = '0') then
			data_line <= not data;
		end if;
	end process;
end arch;