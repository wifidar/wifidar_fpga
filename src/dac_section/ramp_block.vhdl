library IEEE;
use IEEE.std_logic_1164.all;

entity ramp_block is
	port(
		rot_a: in std_logic;
		rot_b: in std_logic;
		button_in: in std_logic_vector(3 downto 0);
		
		new_waveform: out std_logic;
		ramp_data: out std_logic_vector(11 downto 0);

		current_mode_out: out std_logic_vector(1 downto 0);

		clk: in std_logic
	);

end ramp_block;

architecture structural of ramp_block is
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

	component phase_acc
		generic(
			sine_length_bits: integer := 10
		);
		port(
			x_out: out std_logic_vector(sine_length_bits - 1 downto 0);
			freq_mult: in std_logic_vector(9 downto 0);
			phase_in: in std_logic_vector(7 downto 0);
			new_signal: out std_logic;
			clk: in std_logic
		);
	end component;

	component dac_controller
		generic(
			sine_length_bits: integer := 10;
			num_channels: integer := 1
		);
		port(
			-- sine wave control related
			freq_mult: out std_logic_vector((num_channels * 10) - 1 downto 0);
			offset_adjust: out std_logic_vector((num_channels * 12) - 1 downto 0);
			amplitude_adjust: out std_logic_vector((num_channels * 6) - 1 downto 0);

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
			adjust: in std_logic_vector(11 downto 0)
		);
	end component;

	signal curr_ramp_sig: std_logic_vector(11 downto 0);
	signal curr_x_sig: std_logic_vector(9 downto 0);
	signal current_mode_sig: std_logic_vector(1 downto 0);
	signal current_channel_sig: std_logic_vector(1 downto 0);
	signal adjust_sig: std_logic_vector(1 downto 0);

	signal freq_mult_sig: std_logic_vector(9 downto 0);

	signal offset_adjust_sig: std_logic_vector(11 downto 0);
	signal amplitude_adjust_sig: std_logic_vector(5 downto 0);

	signal amplitude_adjusted_ramp: std_logic_vector(11 downto 0);

begin
	ramp: ramp_gen port map (curr_x_sig,curr_ramp_sig);
	buttons: buttonStructural port map (rot_a,rot_b,button_in,current_mode_sig,current_channel_sig,adjust_sig,clk);
	phase_accumulator: phase_acc port map (curr_x_sig,freq_mult_sig,"00000000",new_waveform,clk);

	controller: dac_controller port map (freq_mult_sig,offset_adjust_sig,amplitude_adjust_sig,current_mode_sig,current_channel_sig,adjust_sig,clk);

	amp_adj: amplitude_adjust port map (curr_ramp_sig,amplitude_adjusted_ramp,amplitude_adjust_sig,clk);

	off_adj: offset_adjust port map (amplitude_adjusted_ramp,ramp_data,offset_adjust_sig);

	current_mode_out <= current_mode_sig;

end structural;
