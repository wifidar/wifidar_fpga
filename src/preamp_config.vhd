library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity preamp_config is
	port(
		preamp_done: out std_logic;
		send_data: in std_logic;
		busy: out std_logic;
		
		spi_mosi: out std_logic;
		spi_sck: out std_logic;
		
		clk: in std_logic
	);
end preamp_config;

architecture Behavioral of preamp_config is
	type spi_state is (reset,sending,waiting);
	signal curr_state: spi_state;

	signal divide_count: integer range 0 to 10;
	signal divided_clk: std_logic;
	
	signal spi_count: integer range 0 to 9;
	signal spi_clk_sig: std_logic := '0';

begin

	clk_div: process(clk)
	begin
		if(rising_edge(clk)) then
			case curr_state is
				when reset =>
					divided_clk <= '0';
					divide_count <= 0;
				when sending =>
					divided_clk <= '0';
					divide_count <= divide_count + 1;
					if(divide_count = 10) then
						divide_count <= 0;
						divided_clk <= '1';
					end if;
				when waiting =>
				
			end case;
		end if;
	end process;

	process(clk)
	begin
		if(rising_edge(clk)) then
			case curr_state is
				when reset =>
					curr_state <= waiting;
				when sending =>
					busy <= '1';
					if(divided_clk = '1') then
						if(spi_count <= 9) then
							spi_clk_sig <= not spi_clk_sig;
						end if;
						
						if(spi_clk_sig = '1') then
							if(spi_count <= 9) then
								spi_count <= spi_count + 1;
								preamp_done <= '0';
								spi_clk_sig <= '0';
							else
								preamp_done <= '1';
							end if;
							case spi_count is
								when 0 =>
									--amp_cs <= '1';
								when 1 =>
									--amp_cs <= '0';
									spi_mosi <= '1';
								when 2 =>
									spi_mosi <= '0';
								when 3 =>
									spi_mosi <= '0';
								when 4 =>
									spi_mosi <= '0';
								when 5 =>
									spi_mosi <= '0';
								when 6 =>
									spi_mosi <= '0';
								when 7 => 
									spi_mosi <= '1';
								when 8 =>
									spi_mosi <= '0';
								when others =>
									spi_mosi <= '0';
									--amp_cs <= '1';
									preamp_done <= '1';
									curr_state <= waiting;
									spi_clk_sig <= '0';
							end case;
						end if;
					end if;
				when waiting =>
					spi_clk_sig <= '0';
					spi_count <= 0;
					spi_mosi <= '0';
					
					busy <= '0';
					if(send_data = '1') then
						curr_state <= sending;
					end if;
			end case;
		end if;
	end process;

	spi_sck <= spi_clk_sig;

end Behavioral;

