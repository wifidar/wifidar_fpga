library IEEE;
use IEEE.std_logic_1164.all;

entity wifidar_fpga is
	port(
		rot_a: in std_logic;
		rot_b: in std_logic;
		button_in: in std_logic_vector(3 downto 0);
		
		SPI_SS_B: out std_logic;
		AMP_CS: out std_logic;
		AD_CONV: out std_logic;
		SF_CE0: out std_logic;
		FPGA_INIT_B: out std_logic;
		
		SPI_MOSI: out std_logic;
		DAC_CS: out std_logic;
		SPI_SCK: out std_logic;
		DAC_CLR: out std_logic;

		current_mode_out: out std_logic_vector(1 downto 0);

		uart_tx: out std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end wifidar_fpga;

architecture structural of wifidar_fpga is
	component ramp_block
		port(
			rot_a: in std_logic;
			rot_b: in std_logic;
			button_in: in std_logic_vector(3 downto 0);
			
			new_waveform: out std_logic;
			ramp_data: out std_logic_vector(11 downto 0);

			current_mode_out: out std_logic_vector(1 downto 0);

			clk: in std_logic
		);
	end component;

	component uart
		generic(
			clk_freq: integer := 50000000;
			baud_rate: integer := 38400
		);
		port(
			uart_tx: out std_logic;
			
			data_in: in std_logic_vector(7 downto 0);

			ready: out std_logic;
			send_data: in std_logic;

			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component sample_buffer
		generic(
			sample_length_bits: integer range 0 to 32 := 14;
			num_samples: integer range 0 to 20000 := 500
		);
		port(
			sample_in: in std_logic_vector(sample_length_bits - 1 downto 0);
			sample_out: out std_logic_vector(sample_length_bits - 1 downto 0);

			sample_in_ready: in std_logic;

			sample_out_index: in std_logic_vector(ceil(log(num_samples)/log(2)) downto 0);
			buffer_full: out std_logic;
			
			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component adc_controller
		generic(
			sample_div: integer := 2500
		);
		port(
			spi_to_amp: out std_logic_vector(3 downto 0);
			req_adc: out std_logic;
			req_amp: out std_logic;
			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component uart_minibuf
		generic(
			sample_length_bits: integer range 0 to 32 := 14;
		);
		port(
			data_in: in std_logic_vector (sample_length_bits -1 downto 0);
			
			data_out: out std_logic_vector(7 downto 0);

			index_data_in: out std_logic_vector(9 downto 0);

			sample_buffer_full: in std_logic;
			uart_send_data: out std_logic;
			uart_ready: in std_logic;

			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component spi_arbitrator
		port(
			----- other devices on SPI BUS ---
			SPI_SS_B: out std_logic;  -- set to 1
			SF_CE0: out std_logic;  -- set to 1
			FPGA_INIT_B: out std_logic;  -- set to 1

			----- chip selects ---
			AMP_CS: out std_logic;  -- active low pre-amp chip select
			AD_CONV: out std_logic;  -- active high ADC chip select
			DAC_CS: out std_logic;  -- active low DAC chip select

			----- resets ---
			DAC_CLR: out std_logic;  -- DAC clear signal (active low)
			AMP_SHDN: out std_logic; -- ADC pre-amp shutdown signal (active high)

			-- control signals
			spi_controller_busy: in std_logic;
			spi_controller_send_data: out std_logic;
			spi_data_width: out std_logic_vector(5 downto 0);
			spi_data_in: out std_logic_vector(33 downto 0);
			spi_data_out: in std_logic_vector(33 downto 0);
			
			to_adc_controller: out std_logic_vector(13 downto 0);
			to_amp: in std_logic_vector(3 downto 0);
			ramp_in: in std_logic_vector(9 downto 0);
			
			req_adc: in std_logic;
			req_amp: in std_logic;

			load_adc: out std_logic;

			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component spi_controller
		port(
			--- SPI signals ---
			SPI_SCK: out std_logic;  -- spi clock
			SPI_MOSI: out std_logic;  -- Master output, slave input
			SPI_MISO: in std_logic;  -- Master input, slave output

			--- control ---
			busy: out std_logic;
			send_data: in std_logic;  -- send data over SPI
			spi_data_width: in std_logic_vector(5 downto 0);
			spi_clk_div: in std_logic_vector(1 downto 0); -- divider required for spi clock
			spi_data_in: in std_logic_vector(33 downto 0);
			spi_data_out: out std_logic_vector(33 downto 0);
			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	signal new_waveform_sig: std_logic;
	signal ramp_data_sig: std_logic_vector(11 downto 0);

	signal num_samples: integer := 500;

	signal uart_data: std_logic_vector(7 downto 0);
	signal uart_send_data: std_logic;
	signal uart_ready: std_logic;

	signal adc_sample_data: std_logic_vector(13 downto 0);
	signal sample_buffer_out: std_logic_vector(13 downto 0);
	signal load_adc: std_logic;
	signal sample_out_index: std_logic_vector(ceil(log(num_samples)/log(2)) downto 0);
	signal sample_buffer_full: std_logic;

	signal spi_to_amp: std_logic_vector(3 downto 0);
	signal req_adc: std_logic;
	signal req_amp: std_logic;

	signal spi_controller_busy: std_logic;
	signal spi_controller_send_data: std_logic;
	signal spi_data_width: std_logic_vector(5 downto 0);
	signal spi_data_in: std_logic_vector(33 downto 0);
	signal spi_data_out: std_logic_vector(33 downto 0);
begin
	ramp_generator: ramp_block port map (rot_a,rot_b,button_in,new_waveform_sig,ramp_data_sig,current_mode_out,clk);

	uarter: uart port map (uart_tx,uart_data,uart_ready,uart_send_data,rst,clk);

	sample_buefferer: sample_buffer port map (adc_sample_data,sample_buffer_out,load_adc,sample_out_index,sample_buffer_full,rst,clk);

	adc_controllerer: adc_controller port map (spi_to_amp,req_adc,req_amp,rst,clk);

	uart_minibuffer: uart_minibuf port map (sample_buffer_out,uart_data,sample_out_index,sample_buffer_full,uart_send_data,uart_ready,rst,clk);

	spi_arbitratorer: spi_arbitrator port map (SPI_SS_B,SF_CE0,FPGA_INIT_B,AMP_CS,AD_CONV,DAC_CS,DAC_CLR,AMP_SHDN,
								spi_controller_busy,spi_controller_send_data,spi_data_width,spi_data_in,spi_data_out,
								adc_sample_data,spi_to_amp,ramp_data_sig,req_adc,req_amp,load_adc,rst,clk);

	spi_controllerer: spi_controller port map (SPI_SCK,SPI_MOSI,SPI_MISO,spi_controller_busy,spi_controller_send_data,
								spi_data_width,spi_data_in,spi_data_out,rst,clk);
end structural;
