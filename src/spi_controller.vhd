library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_controller is
	port(
		----- other devices on SPI BUS ---
		--SPI_SS_B: out std_logic;  -- set to 1
		--SF_CE0: out std_logic;  -- set to 1
		--FPGA_INIT_B: out std_logic;  -- set to 1

		----- chip selects ---
		--AMP_CS: out std_logic;  -- active low pre-amp chip select
		--AD_CONV: out std_logic;  -- active high ADC chip select
		--DAC_CS: out std_logic;  -- active low DAC chip select

		----- resets ---
		--DAC_CLR: out std_logic;  -- DAC clear signal (active low)
		--AMP_SHDN: out std_logic; -- ADC pre-amp shutdown signal (active high)

		--- SPI signals ---
		SPI_SCK: out std_logic;  -- spi clock
		SPI_MOSI: out std_logic;  -- Master output, slave input
		SPI_MISO: in std_logic;  -- Master input, slave output

		--- control ---
		busy: out std_logic;
		send_data: in std_logic;  -- send data over SPI
		spi_data_width: in std_logic_vector(4 downto 0);
		spi_clk_div: in std_logic_vector(1 downto 0); -- divider required for spi clock
		spi_data_in: in std_logic_vector(33 downto 0);
		spi_data_out: out std_logic_vector(33 downto 0);
		rst: in std_logic;
		clk: in std_logic
	);
end spi_controller;

architecture Behavioral of spi_controller is

	type spi_state is (reset,sending,waiting);
	signal curr_state: spi_state;

	signal curr_bit: integer range 0 to 33;
	signal curr_clk_cnt: integer range 0 to 3;
	signal spi_clk: std_logic := '0';
	signal temp_data: std_logic_vector(33 downto 0) := (others => '0');
	signal temp: std_logic;
	
begin

	process(clk,rst)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(clk)) then
			case curr_state is
				when reset =>
					curr_bit <= 0;
					curr_clk_cnt <= 0;
					spi_clk <= '0';
					SPI_MOSI <= '0';
					busy <= '0';
					curr_state <= waiting;
				when sending =>
					busy <= '1';
					curr_clk_cnt <= curr_clk_cnt + 1;
					if(curr_clk_cnt = to_integer(unsigned(spi_clk_div))) then
						curr_clk_cnt <= 0;
						spi_clk <= not spi_clk;
					end if;
					if(spi_clk = '1') then
						if(temp = '1') then
							temp <= '0';
							curr_bit <= curr_bit + 1;
						end if;
						SPI_MOSI <= spi_data_in(curr_bit);
						if(curr_bit = to_integer(unsigned(spi_data_width)) and temp = '1') then
							busy <= '0';
							curr_state <= waiting;
						end if;
					end if;
					if(spi_clk = '0') then
						temp <= '1';
						temp_data(curr_bit) <= SPI_MISO;
					end if;
				when waiting =>
					curr_bit <= 0;
					curr_clk_cnt <= 0;
					spi_clk <= '0';
					SPI_MOSI <= '0';
					busy <= '0';
					spi_data_out <= temp_data;
					if(send_data = '1') then
						curr_state <= sending;
					end if;
			end case;
		end if;
	end process;

	SPI_SCK <= spi_clk;

end Behavioral;

