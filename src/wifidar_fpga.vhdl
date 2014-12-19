library IEEE;
use IEEE.std_logic_1164.all;

entity wifidar_fpga is
	port(
		led: out std_logic
	);

end wifidar_fpga;

architecture structural of wifidar_fpga is

begin
	led <= '1';

end structural;
