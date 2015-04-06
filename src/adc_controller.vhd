library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc_controller is
	generic(
		sample_div: integer := 2500;
	);
	port(
		spi_from_adc: in std_logic_vector(13 downto 0);
		spi_to_amp: out std_logic_vector(3 downto 0);
		adc_to_uart: out std_logic_vector(13 downto 0);
		--uart_to_amp: in std_logic_vector(3 downto 0);
		req_adc: out std_logic;
		req_amp: out std_logic;
		--serial_adc_req: in std_logic;
		--serial_amp_req: in std_logic;
		load_adc: in std_logic;
		rst: in std_logic;
		clk: in std_logic
	);
end adc_controller;

architecture Behavioral of adc_controller is
	type adc_state is (reset_amp,normal_op,update_adc); -- TODO: add serial update and ability to update amplifier
	signal curr_state: adc_state;

	signal count_before_adc_req: integer range 0 to 50000;
	signal adc_data: std_logic_vector(13 downto 0);
	
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
			req_adc <= '0';
			if(load_adc = '1') then
				adc_data <= spi_from_adc;
			end if;
			case adc_state is
				when reset_amp =>
					req_amp <= '1';
					spi_to_amp <= "0001";
					curr_state <= normal_op;
				when normal_op =>
					count_before_adc_req <= count_before_adc_req + 1;
					if(count_before_adc_req = sample_div - 1) then
						adc_state <= update_adc;
					end if;
				when update_adc =>
					req_adc <= '1';
					curr_state <= normal_op;
			end case;
		end if;
	end process;

	adc_to_uart <= adc_data;

end Behavioral;

