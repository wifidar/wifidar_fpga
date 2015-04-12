library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_arbitrator is
	port(
		----- other devices on SPI BUS ---
		SPI_SS_B: out std_logic;  -- set to 1
		SF_CE0: out std_logic;  -- set to 1
		FPGA_INIT_B: out std_logic;  -- set to 1

		----- chip selects ---
		AMP_CS: out std_logic;  -- active low pre-amp chip select
		--AD_CONV: out std_logic;  -- active high ADC chip select
		DAC_CS: out std_logic;  -- active low DAC chip select

		----- resets ---
		DAC_CLR: out std_logic;  -- DAC clear signal (active low)
		AMP_SHDN: out std_logic; -- ADC pre-amp shutdown signal (active high)

		-- control signals
		spi_controller_busy: in std_logic;
		
		adc_send_data: out std_logic;
		amp_send_data: out std_logic;
		dac_send_data: out std_logic;
		
		req_adc: in std_logic;
		req_amp: in std_logic;

		rst: in std_logic;
		clk: in std_logic
	);
end spi_arbitrator;

architecture Behavioral of spi_arbitrator is
	type arbitration_type is (dac,adc,amp);
	signal curr_state: arbitration_type := dac;

	signal amp_requested: std_logic;
	signal adc_requested: std_logic;
	
begin

	process(clk,rst)
	begin
		if(rst = '1') then
			curr_state <= dac;
			adc_send_data <= '0';
			dac_send_data <= '0';
			amp_send_data <= '0';
		elsif(rising_edge(clk)) then
			if(spi_controller_busy = '1') then
				adc_send_data <= '0';
				dac_send_data <= '0';
				amp_send_data <= '0';
				curr_state <= dac;
				if(req_amp = '1') then
					amp_requested <= '1';
				elsif(req_adc = '1') then
					adc_requested <= '1';
				end if;
			else
				case curr_state is
					when dac =>
						DAC_CS <= '0';
						AMP_CS <= '1';
						--AD_CONV <= '0';

						if(amp_requested = '1') then
							curr_state <= amp;
							amp_requested <= '0';
						elsif(adc_requested = '1') then
							curr_state <= adc;
							adc_requested <= '0';
						else
							dac_send_data <= '1';
						end if;
					when adc =>
						DAC_CS <= '1';
						AMP_CS <= '1';
						--AD_CONV <= '1';
						adc_send_data <= '1';
					when amp =>
						DAC_CS <= '1';
						AMP_CS <= '0';
						--AD_CONV <= '0';
						amp_send_data <= '1';
					when others =>
				end case;
			end if;
		end if;
	end process;

	SPI_SS_B <= '1';
	SF_CE0 <= '1';
	FPGA_INIT_B <= '1';

	DAC_CLR <= '1';
	AMP_SHDN <= '0';
end Behavioral;

