library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity uart is
	generic(
		clk_freq: integer := 50000000;
		baud_rate: integer := 115200
	);
	port(
		uart_tx: out std_logic;
		
		data_in: in std_logic_vector(7 downto 0);

		ready: out std_logic;
		send_data: in std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end uart;

architecture behavioral of uart is

	type uart_state is (reset,waiting,sending);
	signal curr_state: uart_state;

	signal clock_divide: integer range 0 to 5208 := 0;

	signal slow_clock: std_logic := '0';

	signal uart_tx_sig: std_logic;

	signal current_bit: integer range 0 to 9;

begin
	slower_clock: process(clk,rst)
	begin
		if(rst = '1') then
			clock_divide <= 0;
			slow_clock <= '0';
		elsif(rising_edge(clk)) then
			clock_divide <= clock_divide + 1;
			if(clock_divide = 215) then  -- 651->38400 baud
				clock_divide <= 0;
				slow_clock <= not slow_clock;
			end if;
		end if;
	end process;

	main_uart: process(slow_clock,rst)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(slow_clock)) then
			case curr_state is
				when reset =>
					uart_tx_sig <= '1';
					curr_state <= waiting;
				when waiting =>
					ready <= '1';
					current_bit <= 0;
					uart_tx_sig <= '1';
					if(send_data = '1') then
						curr_state <= sending;
					end if;
				when sending =>
					ready <= '0';
					current_bit <= current_bit + 1;
					if(current_bit = 9) then
						current_bit <= 0;
						uart_tx_sig <= '1';
						curr_state <= waiting;
					elsif(current_bit = 0) then
						uart_tx_sig <= '0';
					else
						uart_tx_sig <= data_in(current_bit - 1);
					end if;
			end case;
		end if;
	end process;
	uart_tx <= uart_tx_sig;

end behavioral;
