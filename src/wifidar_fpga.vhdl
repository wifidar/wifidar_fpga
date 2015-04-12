library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity wifidar_fpga is
	generic(
		num_samples: integer range 0 to 20000 := 195;
		sample_length_bits: integer range 0 to 32 := 14
	);
	port(
		rot_a: in std_logic;
		rot_b: in std_logic;
		button_in: in std_logic_vector(3 downto 0);
		
		SPI_SS_B: out std_logic;
		AMP_CS: out std_logic;
		AD_CONV: out std_logic;
		SF_CE0: out std_logic;
		FPGA_INIT_B: out std_logic;
		AMP_SHDN: out std_logic;
		
		SPI_MOSI: out std_logic;
		SPI_MISO: in std_logic;
		SPI_SCK: out std_logic;
		
		DAC_SCK: out std_logic;
		DAC_CS: out std_logic;
		DAC_MOSI: out std_logic;

		current_mode_out: out std_logic_vector(1 downto 0);

		uart_tx: out std_logic;
		debug: out std_logic;
		debug2: out std_logic;

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
			num_samples: integer range 0 to 20000 := 20;
			sample_length_bits: integer range 0 to 32 := 14
		);
		port(
			sample_in: in std_logic_vector(sample_length_bits - 1 downto 0);
			sample_out: out std_logic_vector(sample_length_bits - 1 downto 0);

			sample_in_ready: in std_logic;
			initial_sample: in std_logic;

			sample_out_index: in std_logic_vector(integer(ceil(log(real(num_samples))/log(real(2)))) downto 0);
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
			num_samples: integer range 0 to 20000 := 20;
			sample_length_bits: integer range 0 to 32 := 14
		);
		port(
			data_in: in std_logic_vector (sample_length_bits -1 downto 0);
			
			data_out: out std_logic_vector(7 downto 0);

			index_data_in: out std_logic_vector(integer(ceil(log(real(num_samples))/log(real(2)))) downto 0);

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
			--AD_CONV: out std_logic;  -- active high ADC chip select
			--DAC_CS: out std_logic;  -- active low DAC chip select

			----- resets ---
			AMP_SHDN: out std_logic; -- ADC pre-amp shutdown signal (active high)

			-- control signals
			spi_controller_busy: in std_logic;
			dac_ready: in std_logic;
			
			adc_send_data: out std_logic;
			amp_send_data: out std_logic;
			dac_send_data: out std_logic;
			
			req_adc: in std_logic;
			req_amp: in std_logic;

			rst: in std_logic;
			clk: in std_logic
		);
	end component;

	component adc_receiver
		port(
			send_data: in std_logic;
			busy: out std_logic;
			spi_sck: out std_logic;
			spi_miso: in std_logic;
			ad_conv: out std_logic;
			outputA: out std_logic_vector (13 downto 0);
			outputB: out std_logic_vector (13 downto 0);
			new_reading: out std_logic;
			clk: in std_logic
		);
	end component;
	
	component preamp_config
		port(
			preamp_done: out std_logic;
			send_data: in std_logic;
			busy: out std_logic;
			
			spi_mosi: out std_logic;
			spi_sck: out std_logic;
			
			clk: in std_logic
		);
	end component;
	
	component dac_serial
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
	end component;
	
	signal new_waveform_sig: std_logic;
	signal ramp_data_sig: std_logic_vector(11 downto 0);

	signal uart_data: std_logic_vector(7 downto 0);
	signal uart_send_data: std_logic;
	signal uart_ready: std_logic;

	signal adc_sample_data: std_logic_vector(13 downto 0);
	signal sample_buffer_out: std_logic_vector(13 downto 0);
	signal load_adc: std_logic;
	signal sample_out_index: std_logic_vector(integer(ceil(log(real(num_samples))/log(real(2)))) downto 0);
	signal sample_buffer_full: std_logic;

	--signal spi_to_amp: std_logic_vector(3 downto 0);
	signal req_adc: std_logic;
	signal req_amp: std_logic;

	signal spi_controller_busy: std_logic;
	
	signal spi_mosi_sig2: std_logic;
	
	signal spi_sck_sig2: std_logic;
	signal spi_sck_sig3: std_logic;
	
	signal dac_ready: std_logic;
	signal dac_send: std_logic;
	
	signal adc_busy: std_logic;
	signal adc_send: std_logic;
	
	signal amp_send: std_logic;
	signal amp_busy: std_logic;
begin
	ramp_generator: ramp_block port map (rot_a,rot_b,button_in,new_waveform_sig,ramp_data_sig,current_mode_out,clk);

	uarter: uart port map (uart_tx,uart_data,uart_ready,uart_send_data,rst,clk);

	sample_buefferer: sample_buffer generic map (num_samples,sample_length_bits) port map (adc_sample_data,sample_buffer_out,load_adc,new_waveform_sig,sample_out_index,sample_buffer_full,rst,clk);

	adc_controllerer: adc_controller port map (open,req_adc,req_amp,rst,clk);

	uart_minibuffer: uart_minibuf generic map (num_samples,sample_length_bits) port map (sample_buffer_out,uart_data,sample_out_index,sample_buffer_full,uart_send_data,uart_ready,rst,clk);

	spi_arbitratorer: spi_arbitrator port map (SPI_SS_B,SF_CE0,FPGA_INIT_B,AMP_CS,AMP_SHDN,
								spi_controller_busy,dac_ready,adc_send,amp_send,dac_send,
								req_adc,req_amp,rst,clk);

	dac_controller: dac_serial port map (DAC_SCK,DAC_CS,DAC_MOSI,ramp_data_sig,dac_ready,dac_send,clk);
	
	adc_spi_control: adc_receiver port map (adc_send,adc_busy,spi_sck_sig2,SPI_MISO,AD_CONV,adc_sample_data,open,load_adc,clk);
	
	amp_controller: preamp_config port map (open,amp_send,amp_busy,spi_mosi_sig2,spi_sck_sig3,clk);
	
	SPI_MOSI <= spi_mosi_sig2;
	SPI_SCK <= spi_sck_sig2 or spi_sck_sig3;
	
	spi_controller_busy <= adc_busy or amp_busy;
	
	debug <= sample_buffer_full;
	debug2 <= new_waveform_sig;
	
end structural;
