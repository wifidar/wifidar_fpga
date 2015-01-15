library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc_controller is
	port(
		spi_from_adc: in std_logic_vector(13 downto 0);
		spi_to_amp: out std_logic_vector(3 downto 0);
		adc_to_uart: out std_logic_vector(13 downto 0);
		uart_to_amp: in std_logic_vector(3 downto 0);
		req_adc: out std_logic;
		req_amp: out std_logic;
		serial_adc_req: in std_logic;
		serial_amp_req: in std_logic;
		load_adc: in std_logic;
		rst: in std_logic;
		clk: in std_logic
	);
end adc_controller;

architecture Behavioral of adc_controller is
	type adc_state is (reset_amp,normal_op,update_adc,serial_update_adc,update_amp,serial_update_amp);
	signal curr_state: adc_state;

	signal count_before_adc_req: integer range 0 to 50000;
	signal const_count: integer range 0 to 255;
	
begin
	process(clk,rst)
	begin
		if(rst = '1') then
			curr_state <= reset_amp;
			req_adc <= '0';
			req_amp <= '0';
			adc_to_uart <= (others => '0');
			spi_to_amp <= (others => '0');
		elsif(rising_edge(clk)) then
			req_amp <= '0';
			case adc_state is
				when reset_amp =>
					req_amp <= '1';
					spi_to_amp <= (others => '0');
					curr_state <= normal_op;
				when normal_op =>

			end case;
		end if;
	end process;

end Behavioral;

