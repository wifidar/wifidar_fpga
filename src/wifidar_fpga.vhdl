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

		clk: in std_logic
	);

end wifidar_fpga;

architecture structural of wifidar_fpga is
	component ramp_gen
		generic(
			ramp_length_bits: integer := 10
		);
		port(
			x_in: in std_logic_vector(ramp_length_bits - 1 downto 0);
			ramp_out: out std_logic_vector(11 downto 0) -- 12 bit output for DAC
		);
	end component;

	component buttonStructural
		port(
				rot_a: in std_logic;
				rot_b: in std_logic;
				button_in: in std_logic_vector(3 downto 0);
				current_mode: out std_logic_vector(1 downto 0);
				current_channel: out std_logic_vector(1 downto 0);
				adjust: out std_logic_vector(1 downto 0);
				clk: in std_logic
			);
	end component;

	component dac_spi
		port(
			--- other devices on SPI BUS ---
			SPI_SS_B: out std_logic;  -- set to 1 when DAC in use
			AMP_CS: out std_logic;  -- set to 1 when DAC in use
			AD_CONV: out std_logic;  -- set to 0 when DAC in use
			SF_CE0: out std_logic;  -- set to 1 when DAC in use
			FPGA_INIT_B: out std_logic;  -- set to 1 when DAC in use
			--- this device ---
			SPI_MOSI: out std_logic;  -- Master output, slave (DAC) input
			DAC_CS: out std_logic;  -- chip select
			SPI_SCK: out std_logic;  -- spi clock
			DAC_CLR: out std_logic;  -- reset
			--SPI_MISO: in std_logic;  -- Master input, slave (DAC) output
			--- control ---
			ready_flag: out std_logic;  -- sending data flag
			channel: in std_logic_vector(1 downto 0);
			send_data: in std_logic;  -- send sine data over SPI
			sine_data: in std_logic_vector(11 downto 0);
			reset_dac: in std_logic;
			clk: in std_logic  -- master clock
		);
	end component;

	component phase_acc
		generic(
			sine_length_bits: integer := 10
		);
		port(
			x_out: out std_logic_vector(sine_length_bits - 1 downto 0);
			freq_mult: in std_logic_vector(9 downto 0);
			phase_in: in std_logic_vector(7 downto 0);
			clk: in std_logic
		);
	end component;

	component simple_control
		generic(
			sine_length_bits: integer := 10;
			num_channels: integer := 1
		);
		port(
			-- spi control related
			spi_ready: in std_logic;
			spi_send_data: out std_logic;
			spi_channel: out std_logic_vector(1 downto 0);

			-- sine wave control related
			freq_mult: out std_logic_vector((num_channels * 10) - 1 downto 0);
			offset_adjust: out std_logic_vector((num_channels * 6) - 1 downto 0);
			amplitude_adjust: out std_logic_vector((num_channels * 6) - 1 downto 0);
			pwm_adjust: out std_logic_vector((num_channels * 10) - 1 downto 0);

			-- control related
			current_mode: in std_logic_vector (1 downto 0); -- 00 = freq, 01 = phase, 10 = amplitude
			current_channel: in std_logic_vector(1 downto 0);
			adjust: in std_logic_vector(1 downto 0); -- pulses for adjustment of values, 0 up, 1 down
			clk: in std_logic
		);
	end component;

	component amplitude_adjust
		port(
			sine_in: in std_logic_vector(11 downto 0);
			sine_out: out std_logic_vector(11 downto 0);
			adjust: in std_logic_vector(5 downto 0);
			clk: in std_logic
		);
	end component;

	component offset_adjust
		port(
			ramp_in: in std_logic_vector(11 downto 0);
			ramp_out: out std_logic_vector(11 downto 0);
			adjust: in std_logic_vector(5 downto 0)
		);
	end component;

	signal ramp_out_sig: std_logic_vector(11 downto 0);
	signal x_out_sig: std_logic_vector(9 downto 0);
	signal current_mode_sig: std_logic_vector(1 downto 0);
	signal current_channel_sig: std_logic_vector(1 downto 0);
	signal adjust_sig: std_logic_vector(1 downto 0);

	signal ready_flag_sig: std_logic;
	signal spi_channel: std_logic_vector(1 downto 0);
	signal send_data_sig: std_logic;
	--signal spi_ramp_sig: std_logic_vector(11 downto 0);
	signal reset_dac_sig: std_logic;

	signal freq_mult_sig: std_logic_vector(9 downto 0);

	signal offset_adjust_sig: std_logic_vector(5 downto 0);
	signal amplitude_adjust_sig: std_logic_vector(5 downto 0);

	signal amplitude_adjusted_ramp: std_logic_vector(11 downto 0);
	signal offset_ramp: std_logic_vector(11 downto 0);

begin
	ramp: ramp_gen port map (x_out_sig,ramp_out_sig);
	buttons: buttonStructural port map (rot_a,rot_b,button_in,current_mode_sig,current_channel_sig,adjust_sig,clk);
	spi: dac_spi port map(SPI_SS_B,AMP_CS,AD_CONV,SF_CE0,FPGA_INIT_B,SPI_MOSI,DAC_CS,SPI_SCK,DAC_CLR,ready_flag_sig,spi_channel,send_data_sig,offset_ramp,reset_dac_sig,clk);
	phase_accumulator: phase_acc port map (x_out_sig,freq_mult_sig,"00000000",clk);

	controller: simple_control port map (ready_flag_sig,send_data_sig,spi_channel,freq_mult_sig,offset_adjust_sig,amplitude_adjust_sig,open,current_mode_sig,current_channel_sig,adjust_sig,clk);

	amp_adj: amplitude_adjust port map (ramp_out_sig,amplitude_adjusted_ramp,amplitude_adjust_sig,clk);

	off_adj: offset_adjust port map (amplitude_adjusted_ramp,offset_ramp,offset_adjust_sig);

	current_mode_out <= current_mode_sig;

end structural;
