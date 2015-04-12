library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dac_serial is
	port(
		SPI_SCK: out std_logic;  -- spi clock
		DAC_CS: out std_logic;  -- chip select
		SPI_MOSI_1: out std_logic;  -- Master output, slave (DAC) input
		--SPI_MISO: in std_logic;  -- Master input, slave (DAC) output
		--- control ---
		data_in_1: in std_logic_vector(11 downto 0);
		ready_flag: out std_logic;  -- sending data flag
		send_data: in std_logic;  -- send sine data over SPI
		clk: in std_logic  -- master clock
	);
end dac_serial;

architecture Behavioral of dac_serial is

	signal current_bit: integer range 0 to 15 := 0;
	signal ready_flag_sig: std_logic := '0';
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
						when 2 => SPI_MOSI_1 <= '0';
						when 3 => SPI_MOSI_1 <= '0';
						-- data
						when 4 => SPI_MOSI_1 <= data_in_1(11);
						when 5 => SPI_MOSI_1 <= data_in_1(10);
						when 6 => SPI_MOSI_1 <= data_in_1(9);
						when 7 => SPI_MOSI_1 <= data_in_1(8);
						when 8 => SPI_MOSI_1 <= data_in_1(7);
						when 9 => SPI_MOSI_1 <= data_in_1(6);
						when 10 => SPI_MOSI_1 <= data_in_1(5);
						when 11 => SPI_MOSI_1 <= data_in_1(4);
						when 12 => SPI_MOSI_1 <= data_in_1(3);
						when 13 => SPI_MOSI_1 <= data_in_1(2);
						when 14 => SPI_MOSI_1 <= data_in_1(1);
						when 15 => SPI_MOSI_1 <= data_in_1(0);
						           ready_flag_sig <= '1';
						-- other
						when others  => SPI_MOSI_1 <= '0'; -- used for don't cares
					end case;
				end if;
			else
				dac_cs_delay <= '1';
				current_bit <= 0;
				spi_clk_delay <= dac_cs_delay;
			end if;
			DAC_CS <= dac_cs_delay;
			SPI_SCK <= spi_clk_delay;
			ready_flag <= ready_flag_sig;
		end if;	
	end process;

end Behavioral;

--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;
--
--entity dac_serial is
--	port (
--				 dac_clk: out std_logic;
--				 dac_sync: out std_logic;
--				 dac_data: out std_logic;
--				 data_in: in std_logic_vector(11 downto 0);
--				 ready: out std_logic;
--				 send: in std_logic;
--				 clk: in std_logic
--			 );
--end dac_serial;
--
--architecture behavioral of dac_serial is
--
--	current_bit: unsigned(3 downto 0);
--	divide_counter: unsigned(3 downto 0);
--	sending: std_logic;
--	data_en: std_logic;
--	send_en: std_logic;
--
--begin
--	clk_divide:process(clk)
--	begin
--		if(rising_edge(clk)) then
--			if(divide_counter = to_unsigned(5,4)) then
--				divide_counter <= divide_counter + '1';
--				send_en <= '1';
--			elsif(divide_counter = to_unsigned(10,4)) then
--				divide_counter <= (others => '0');
--				data_en <= '1';
--				send_en <= '1';
--			else
--				divide_counter <= divide_counter + '1';
--				data_en <= '0';
--				send_en <= '0';
--			end if;
--		end if;
--	end process;
--
--	serial_clk: process(clk)
--	begin
--		if(rising_edge(clk)) then
--			if(sending = '1') then
--
--	end process;
--
--	serial_data: process(clk)
--	begin
--		if(rising_edge(clk)) then
--			if(send = '1') and (sending = '0') then
--				sending <= '1';
--				sending <= '1';
--				ready <= '0';
--				current_bit <= "0000";
--				dac_data <= '0';
--			elsif(data_en = '1') then
--				if(sending = '1') then
--					current_bit <= current_bit + '1';
--					dac_sync <= '0';
--					case current_bit is
--						when "0000" =>
--							dac_data <= '0'; -- don't care
--						when "0001" =>
--							dac_data <= '0'; -- don't care
--						when "0010" =>
--							dac_data <= '0'; -- 0 for normal operation
--						when "0011" =>
--							dac_data <= '0'; -- 0 for normal operation
--						when "0100" =>
--							dac_data <= data_in(11);
--						when "0101" =>
--							dac_data <= data_in(10);
--						when "0110" =>
--							dac_data <= data_in(9);
--						when "0111" =>
--							dac_data <= data_in(8);
--						when "1000" =>
--							dac_data <= data_in(7);
--						when "1001" =>
--							dac_data <= data_in(6);
--						when "1010" =>
--							dac_data <= data_in(5);
--						when "1011" =>
--							dac_data <= data_in(4);
--						when "1100" =>
--							dac_data <= data_in(3);
--						when "1101" =>
--							dac_data <= data_in(2);
--						when "1110" =>
--							dac_data <= data_in(1);
--						when "1111" =>
--							dac_data <= data_in(0);
--						when others =>
--							dac_data <= '0';
--					end case;
--				else
--					dac_sync <= '1';
--					ready <= '0';
--					current_bit <= "0000";
--					dac_data <= '0';
--				end if;
--			end if;
--		end if;
--	end process;
--
--end behavioral;
