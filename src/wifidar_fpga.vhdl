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

	signal new_waveform_sig: std_logic;
	signal ramp_data_sig: std_logic_vector(11 downto 0);

begin
	ramp_generator: ramp_block port map (rot_a,rot_b,button_in,new_waveform_sig,ramp_data_sig,current_mode_out,clk);

end structural;
