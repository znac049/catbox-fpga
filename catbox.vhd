library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--
-- Implementation of an Atari CATBOX - a coin-op game board tester.
-- This device was released in the late 1970's to help engineers
-- fault find game boards. They are hard to find these days, hence
-- my attempt to implement one in an FPGA. All copyrights and 
-- trademarks for the CATBOX remain the property of Atari, Inc.
--
-- This design came from hours of poring over the official Atari
-- schematics and a ROM dump I found online claiming to be the
-- original CATBOX image.
--
-- Bob Green, January 2016. bob@wookey.org.uk
--

--
-- General signal and port naming rules:
--
-- 	1. names that are mostly uppercase refer to a signal
--			name from the schematic, possibly modified a bit
--			for consistency. I will add a table of mappings
--		2. names that are predominantly lowercase (apart from
--			the odd bit of camel-casing) are names I've invented
--			for my convenience and bear no relation back to the
--			schematic.
--		3. the suffix '_n', as per convention, refers to an active
--			low signal. The absence of the suffix implies active
--			high. If it's a schematic signal, I am guided by that.
--		4. if the schematic refers to a signal in both active high
--			and active low modes, I make both available.
--
entity catbox is
	port(
		-- Signals to/from the game board
		--
		-- GAME_CBCLK_DIS  		When connected to the game edge connector, disables 
		--						  		the catbox internal clock so the catbox will use 
		--						  		the game's clock signal.
		GAME_CBCLK_DIS				: in    std_logic;
		--
		-- GAME_PHI2       		Phi2 signal from the game.
		GAME_PHI2					: in	  std_logic;
		--
		-- GAME_RW					Read / ~Write signal from the game. 
		GAME_RW						: in    std_logic;
		--
		-- GAME_n       			????? What does this do?
		GAME_n						: out  std_logic;
		--
		-- GAME_VMA					Only used for games with 6800 processors
		GAME_VMA						: in    std_logic;
		--
		-- GAME_BA					Only used for games with 6800 processors
		GAME_BA						: in    std_logic;
		--
		-- GAME_ABUS(15-0)		16 bit game address bus
		GAME_ABUS					: out   std_logic_vector(15 downto 0);
		--
		-- GAME_DBUS(7-0)			8 bit game data bus
		GAME_DBUS					: inout std_logic_vector(7 downto 0);
		--
		-- End of signals to/from the game board

		-- Signals to/from the control panel
		--
		-- TESTER_RESET_n			The reset button
		TESTER_RESET_n				: in    std_logic;
		--
		-- KBD_COL(6-1)			6 bit keyboard matrix driver
		KBD_COL        			: out   std_logic_vector(6 downto 1);
		-- KBD_ROW(4-1)			4 bit keyboard matrix inputs
		KBD_ROW						: in    std_logic_vector(4 downto 1);
		--
		-- SELFTEST_SW				Selftest selection switch
		SELFTEST_SW					: in    std_logic;
		--
		-- READ_MODE_SW			Select read or write mode
		READ_MODE_SW				: in    std_logic;
		--
		-- K_BYTE_SW				Memory size selection three way switch
		K_BYTE_SW					: in    std_logic;
		-- ONE_BYTE_SW				The other half of the three way switch
		ONE_BYTE_SW					: in    std_logic;
		--
		-- DATA_SEL_SW				Dislay data swicth
		DATA_SEL_SW      			: in    std_logic;
		-- ADDRESS_SEL_SW			Display address switch
		ADDRESS_SEL_SW				: in    std_logic;
		--
		-- ERROR_DATA_DISP_SW	
		ERROR_DATA_DISP_SW		: in    std_logic;
		--
		-- ADDRESS_INC_SW
		ADDRESS_INC_SW				: in    std_logic;
		--
		-- DATA_SET_SW
		DATA_SET_SW					: in    std_logic;
		--
		-- TESTER_MODE_SW
		TESTER_MODE_SW				: in    std_logic;
		--
		-- SRDATA_n					Incoming data stream from the data probe
		SRDATA_n						: in    std_logic;
		-- SIG_START				Trigger signature generation start
		SIG_START					: in    std_logic;
		-- SIG_STOP					End of signature generation
		SIG_STOP						: in    std_logic;
		-- SIG_CLOCK_n				Clock for signature generator
		SIG_CLOCK_n					: in    std_logic;
		--
		-- DP_DIG_SEL(2-0)		3 bits to select a display element
		DP_DIG_SEL					: out   std_logic_vector(2 downto 0);
		-- DP_SEGMENT(8)			The 7 segments plus decimal point of the selected display element
		DP_SEGMENT					: out   std_logic_vector(7 downto 0);
		--
		-- GATE_LED
		GATE_LED						: out   std_logic;		
		--
		-- End of signals to/from the control panel
		
		-- 50MHz clock module
		clk							: in    std_logic
	); 
end catbox;

architecture arch of catbox is
	signal cpuClock      : std_logic := '0';
	signal cpuClockCount : std_logic_vector(5 downto 0);
	
	signal R_W_n         : std_logic;
	signal cpuAddress		: std_logic_vector(15 downto 0);
	signal cpuDataOut		: std_logic_vector(7 downto 0);
	signal cpuDataIn		: std_logic_vector(7 downto 0);
	signal IRQ_n			: std_logic := '1';

	-- Misc enable signals
	-- ROM_SEL    			
	signal ROM_SEL_n		: std_logic;
	-- R6532_SEL         
	signal R6532_SEL_n	: std_logic;
	-- IN_SEL
	signal IN_SEL_n		: std_logic;
	
	-- SEGMENTS_SEL_n		Writing to address $2b00 latches 7 segment data
	signal SEGMENTS_SEL_n: std_logic := '0';
	-- DIGITS_SEL_n		Writing to address $3000 selects digit and enables common anode
	signal DIGITS_SEL_n  : std_logic := '0';
	-- SIGRST_SEL			Writing to address $3800 causes signature analyser reset
	signal SIGRST_SEL_n	: std_logic;
	
	-- SIG					The output from the signature CRC generator
	signal SIG           : std_logic_vector(15 downto 0);
	-- RUN_STOP
	signal RUN_STOP		: std_logic;
	-- STOP_LATCH			Signals that the stop pulse has been seen
	signal STOP_LATCH		: std_logic;

	-- STATIC
	signal STATIC			: std_logic;

	-- DBUS_LD
	signal DBUS_LD			: std_logic;
	-- ABUS_LD
	signal ABUS_LD			: std_logic;
	-- ABUS_EN
	signal ABUS_EN			: std_logic;
	-- ABUS_EN_n
	signal ABUS_EN_n		: std_logic;
	--DBUS_IN_n
	signal DBUS_IN_n		: std_logic;
	
	-- GAME
	signal GAME				: std_logic;

	-- COUNTEN
	signal COUNTEN			: std_logic;
	-- COUNTEN_n
	signal COUNTEN_n		: std_logic;
	
	-- SEGMENTS_SEL		Writing to address $2b00 latches 7 segment data
	signal SEGMENTS_SEL  : std_logic := '0';
	-- DIGITS_SEL			Writing to address $3000 selects digit and enables common anode
	signal DIGITS_SEL    : std_logic := '0';
	-- SIGRST_SEL			Writing to address $3800 causes signature analyser reset

	-- romData				
	signal romData			: std_logic_vector(7 downto 0);
	-- r6532Data
	signal r6532Data		: std_logic_vector(7 downto 0);
	
	
	
	
	
	
	
	
	signal n_400x			: std_logic;
	
	signal n_4100			: std_logic;
	
	signal swreg			: std_logic_vector(7 downto 0);
	
begin	
	cpu : entity work.T65 port map(
		Mode           => "00",      -- "00" => 6502, "01" => 65C02, "10" => 65C816
		Res_n          => TESTER_RESET_n,
		Enable         => '1',
		Clk            => cpuClock,
		Rdy            => '1',
		Abort_n        => '1',
		IRQ_n          => IRQ_n,
		NMI_n          => '1',
		SO_n           => '1',
		R_W_n          => R_W_n,
		A(15 downto 0) => cpuAddress,
		DI             => cpuDataIn,
		DO             => cpuDataOut
	);
	
	rom : entity work.atari_rom port map(
		address => cpuAddress(10 downto 0),
		clock   => '1',
		q       => romData
	);
	
	leds : entity work.display port map(
		segments_n => SEGMENTS_SEL,
		digits_n   => DIGITS_SEL,
		rst        => TESTER_RESET_n,
		data       => cpuDataOut,
		segments   => DP_SEGMENT,
		COUNTEN    => COUNTEN,
		DIGSEL     => DP_DIG_SEL
	);
	
	riot : entity work.r6532 port map(
		phi2 => cpuClock,
		res_n => TESTER_RESET_n,
		CS1 => '1',
		CS2_n => r6532_SEL_n,
		RS_n => not cpuAddress(7),
		R_W => R_W_n,
		addr => cpuAddress(6 downto 0),
		dataIn => cpuDataOut,
		dataOut => r6532Data,
		pa => SIG(15 downto 8),
		pb => SIG(7 downto 0),
		IRQ_n => IRQ_n
	);

--	abus_counter : entity work.counter16 port map(
--		clk => cpuClock,
--		out_en => '1',
--		data => abus
--	);
	
	sigger : entity work.sig16 port map(
		clk => cpuClock,
		data => SRDATA_n,
		rst => SIGRST_SEL_n,
		run_stop => '0',
		sig => SIG
	);

	-- Chip select generation
	ROM_SEL_n  <= '0' when cpuAddress(15 downto 13) = "111" else '1';
	R6532_SEL_n <= '0' when cpuAddress(15 downto 11) = "00000" else '1';
	n_400x   <= '0' when cpuAddress(15 downto 4) = "010000000000" else '1';
	n_4100   <= '0' when cpuAddress = "0100000000000000" else '1';
	
	-- Misc useful internal signals
	ABUS_EN_n <= not ABUS_EN;
	GAME_n <= not GAME;
	COUNTEN_n <= not COUNTEN;
	
	-- Where does the CPU get it's data at any point?
	cpuDataIn <= romData when (ROM_SEL_n = '0') else
					 r6532Data when ((R6532_SEL_n = '0') and (R_W_n = '1')) else
					 x"FF";

	process(cpuAddress)
	begin
		if (cpuAddress(15 downto 3) = "0100000000000") then
			if (cpuAddress(2 downto 0) = "000") then
				swreg(7) <= ADDRESS_SEL_SW;
			elsif (cpuAddress(2 downto 0) = "001") then
				swreg(7) <= DATA_SEL_SW;
			elsif (cpuAddress(2 downto 0) = "010") then
				swreg(7) <= ONE_BYTE_SW;
			elsif (cpuAddress(2 downto 0) = "011") then
				swreg(7) <= K_BYTE_SW;
			elsif (cpuAddress(2 downto 0) = "100") then
				swreg(7) <= '1';
			elsif (cpuAddress(2 downto 0) = "101") then
				swreg(7) <= READ_MODE_SW;
			elsif (cpuAddress(2 downto 0) = "110") then
				swreg(7) <= SELFTEST_SW;
			elsif (cpuAddress(2 downto 0) = "111") then
				swreg(7) <= STOP_LATCH;
			end if;
		end if;
		
		if (cpuAddress(15 downto 3) = "0100000000001") then
			swreg(4) <= ERROR_DATA_DISP_SW;
			swreg(3) <= ADDRESS_INC_SW;
			swreg(2) <= DATA_SET_SW;
			swreg(1) <= TESTER_MODE_SW;
		end if;
	end process;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- 49 = 1MHz
			-- 33 = 1.5MHz
			-- 24 = 2MHz
			if (cpuClockCount < 33) then
				cpuClockCount <= cpuClockCount + 1;
			else
				cpuClockCount <= (others => '0');
				cpuClock <= not cpuClock;
			end if;
		end if;
	end process;
end arch;
	