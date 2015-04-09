library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart is
	generic(
		clk_freq: integer := 50000000;
		baud_rate: integer := 38400
	);
	port(
		uart_tx: out std_logic;
		
		--data_in: in std_logic_vector(sample_length_bits - 1 downto 0);
		data_in: in std_logic_vector(7 downto 0);

		--curr_sample_index: out std_logic_vector(9 downto 0);
		--request_new_sample: out std_logic;
		ready: out std_logic;

		run: in std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end uart;

architecture structural of uart is

	type uart_state is (reset,waiting,sending);
	signal curr_state: uart_state;

	signal clock_divide: integer range 0 to 5208 := 0;

	signal slow_clock: std_logic := '0';

	signal uart_tx_sig: std_logic;

	signal current_bit: integer range 0 to 7;

begin
	slower_clock: process(clk)
	begin
		if(rst = '1') then
			clock_divide <= '0';
			slow_clock <= '0';
		elsif(rising_edge(clk)) then
			clock_divide <= clock_divide + 1;
			if(clock_divide = ceil(clk_freq/(2*baud_rate))) then  -- 651->38400 baud
				clock_divide <= 0;
				slow_clock <= not slow_clock;
			end if;
		end if;
	end process;

	main_uart: process(slow_clock)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(slow_clock)) then
			case curr_state is
				when reset =>
					uart_tx_sig <= '1';
				when waiting =>
					ready <= '1';
					current_bit <= 0;
					uart_tx_sig <= '1';
				when sending =>
					ready <= '0';
					current_bit <= current_bit + 1;
					uart_tx_sig <= data_in(current_bit);
					if(current_bit = 7) then
						current_bit <= 0;
						curr_state <= waiting;
					end if;
			end case;
		end if;
	end process;


end structural;
