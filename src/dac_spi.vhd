library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dac_spi is
	port(
		--- other devices on SPI BUS ---
--		SPI_SS_B: out std_logic;  -- set to 1 when DAC in use
--		AMP_CS: out std_logic;  -- set to 1 when DAC in use
----		AD_CONV: out std_logic;  -- set to 0 when DAC in use
--		SF_CE0: out std_logic;  -- set to 1 when DAC in use
--		FPGA_INIT_B: out std_logic;  -- set to 1 when DAC in use
		--- this device ---
		SPI_MOSI: out std_logic;  -- Master output, slave (DAC) input
		--DAC_CS: out std_logic;  -- chip select
		SPI_SCK: out std_logic;  -- spi clock
		--DAC_CLR: out std_logic;  -- reset
		--SPI_MISO: in std_logic;  -- Master input, slave (DAC) output
		--- control ---
		ready_flag: out std_logic;  -- sending data flag
		channel: in std_logic_vector(1 downto 0);
		send_data: in std_logic;  -- send sine data over SPI
		sine_data: in std_logic_vector(11 downto 0);
		--reset_dac: in std_logic;
		clk: in std_logic  -- master clock
	);
end dac_spi;

architecture Behavioral of dac_spi is

	signal current_bit: integer range 0 to 23 := 0;
	signal ready_flag_sig: std_logic := '1';
	signal spi_clk_delay: std_logic;
	signal dac_cs_delay: std_logic;
	
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(send_data = '1') and (ready_flag_sig = '1') then
				ready_flag_sig <= '0';
				dac_cs_delay <= '0';
			elsif ready_flag_sig = '0' then
				if(spi_clk_delay = '1') then
					spi_clk_delay <= '0';
				else
					spi_clk_delay <= '1';
					
					current_bit <= current_bit + 1;
					case current_bit is
						-- command
						when 0 => SPI_MOSI <= '0';
						when 1 => SPI_MOSI <= '0';
						when 2 => SPI_MOSI <= '1';
						when 3 => SPI_MOSI <= '1';
						-- channel
						when 4 => SPI_MOSI <= '0';
						when 5 => SPI_MOSI <= '0';
						when 6 => SPI_MOSI <= channel(1);
						when 7 => SPI_MOSI <= channel(0);
						-- data
						when 8 => SPI_MOSI <= sine_data(11);
						when 9 => SPI_MOSI <= sine_data(10);
						when 10 => SPI_MOSI <= sine_data(9);
						when 11 => SPI_MOSI <= sine_data(8);
						when 12 => SPI_MOSI <= sine_data(7);
						when 13 => SPI_MOSI <= sine_data(6);
						when 14 => SPI_MOSI <= sine_data(5);
						when 15 => SPI_MOSI <= sine_data(4);
						when 16 => SPI_MOSI <= sine_data(3);
						when 17 => SPI_MOSI <= sine_data(2);
						when 18 => SPI_MOSI <= sine_data(1);
						when 19 => SPI_MOSI <= sine_data(0);
						when 23 => ready_flag_sig <= '1';
						-- other
						when others  => SPI_MOSI <= '0';
					end case;
				end if;
			else
				dac_cs_delay <= '1';
				current_bit <= 0;
				spi_clk_delay <= '0';
			end if;
			--DAC_CS <= dac_cs_delay;
			--if(ready_flag_sig = '0') then
				SPI_SCK <= spi_clk_delay;
--			else
--				SPI_SCK <= '0';
--			end if;
			ready_flag <= ready_flag_sig;
		end if;	
	end process;
	
	
	--DAC_CLR <= not reset_dac;

	-- disable other devices (not planning on using them in this project so just kept disabled)
--	SPI_SS_B <= '1';
--	AMP_CS <= '1';
--	AD_CONV <= '0';
--	SF_CE0 <= '1';
--	FPGA_INIT_B <= '1';
	--

end Behavioral;

