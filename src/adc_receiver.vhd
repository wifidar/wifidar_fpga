library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity adc_receiver is
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
end adc_receiver;

architecture Behavioral of adc_receiver is

	type adc_read_type is (start_pulse,a_data,b_data,write_data);
	signal adc_state: adc_read_type;
	
	signal outputA_register: std_logic_vector(13 downto 0);
	signal outputB_register: std_logic_vector(13 downto 0);
	
	signal outputA_temp: std_logic_vector(15 downto 0);
	signal outputB_temp: std_logic_vector(15 downto 0);
	signal curr_pos: integer range 0 to 15 := 0;
	
	signal spi_clk_en: std_logic;
	
	signal new_reading_temp: std_logic;
	
	signal en: std_logic;
	
begin
	
	main_proc: process(clk)
	begin
		if(falling_edge(clk)) then
			if(send_data = '1') then
				en <= '1';
				busy <= '1';
			end if;
			if(en = '1') then
				ad_conv <= '0';
				new_reading <= '0';
				busy <= '1';
				
				case adc_state is
					when start_pulse =>
						curr_pos <= curr_pos + 1;
						new_reading_temp <= '1';
						if(curr_pos = 0) then
							ad_conv <= '1';
						end if;
						if(curr_pos = 3) then
							spi_clk_en <= '1';
						end if;
						if(curr_pos = 4) then
							adc_state <= a_data;
							curr_pos <= 15;
						end if;
					when a_data =>
						curr_pos <= curr_pos - 1;
						outputA_temp(curr_pos) <= spi_miso;
						if(curr_pos = 0) then
							curr_pos <= 15;
							adc_state <= b_data;
						end if;
					when b_data =>
						curr_pos <= curr_pos - 1;
						outputB_temp(curr_pos) <= spi_miso;
						if(curr_pos = 0) then
							curr_pos <= 0;
							adc_state <= write_data;
						end if;
					when write_data =>
						curr_pos <= curr_pos + 1;
						outputA_register <= outputA_temp(13 downto 0);
						outputB_register <= outputB_temp(15 downto 2);
						if(new_reading_temp = '1') then
							new_reading <= '1';
							new_reading_temp <= '0';
						end if;
						if(curr_pos = 2) then
							curr_pos <= 0;
							adc_state <= start_pulse;
							spi_clk_en <= '0';
							en <= '0';
							busy <= '0';
						end if;
				end case;
				
--				spi_clk_sig <= not spi_clk_sig;
--				
--				if(spi_clk_sig = '1') then
--					if(curr_pos = 0) then
--						ad_conv <= '1';
--						outputA_register <= input_register(16 downto 3);
--						outputB_register <= input_register(32 downto 19);
--					else
--						ad_conv <= '0';
--					end if;
--					
--					if((curr_pos > 1) and (curr_pos < 33)) then
--						input_register(curr_pos) <= spi_miso;
--					end if;
--					
--					if(curr_pos = 36) then
--						curr_pos <= 0;
--					end if;
--				end if;
			end if;
		end if;
	end process;
	
	spi_sck <= clk when spi_clk_en = '1' else '0';
	
	outputA <= outputA_register;
	outputB <= outputB_register;
	
end Behavioral;

