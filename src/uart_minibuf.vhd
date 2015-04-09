library IEEE;
use IEEE.std_logic_1164.all;

entity uart_minibuf is
	generic(
		sample_length_bits: integer range 0 to 32 := 12;
	);
	port(
		data_in: in std_logic_vector (sample_length_bits -1 downto 0);
		
		data_out: out std_logic_vector(7 downto 0);

		index_data_in: out std_logic_vector(9 downto 0);

		sample_buffer_full: in std_logic;
		uart_send_data: out std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end uart_minibuf;

architecture behavioral of uart_minibuf is

	type uart_minibuf_state is (reset,waiting,upper_half,lower_half);
	signal curr_state: uart_minibuf_state;

	signal curr_index: integer range 0 to 2^10-1 := 0;

	signal uart_triggered: std_logic;
	signal uart_ready_prev: std_logic;

	signal buffer_full_prev: std_logic;
	signal end_buff: std_logic;

begin
	process(clk)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(clk)) then
			uart_ready_prev <= uart_ready;
			buffer_full_prev <= sample_buffer_full;

			if(buffer_full_prev = '1' and buffer_full = '0') then
				end_buff <= '1';
			end if;

			case curr_state is
				when reset =>
					curr_state <= upper_half;
				when waiting =>
					data_out <= (others => '0');
					curr_index <= 0;
					uart_send_data <= '0';
					if(sample_buffer_full = '1') then
						curr_state <= upper_half;
					end if;
				when upper_half =>
					data_out <= "10" & data_in(14 downto 8);
					uart_send_data <= '0';
					if(uart_ready = '1' and uart_triggered = '0') then
						uart_send_data <= '1';
						uart_triggered <= '1';
					elsif(uart_ready = '1' and uart_ready_prev = '0' and uart_triggered = '1') then
						curr_state <= lower_half;
						uart_triggered <= '0';
					end if;
				when lower_half =>
					curr_index <= curr_index + 1;
					data_out <= data_in(7 downto 0);
					uart_send_data <= '0';
					if(uart_ready = '1' and uart_triggered = '0') then
						uart_send_data <= '1';
						uart_triggered <= '1';
					elsif(uart_ready = '1' and uart_ready_prev = '0' and uart_triggered = '1') then
						curr_state <= upper_half;
						uart_triggered <= '0';
					end if;
					if(end_buff = '1') then
						end_buff <= '0';
						curr_state <= waiting;
					end if;
			end case;
		end if;
	end process;

	index_data_in <= std_logic_vector(to_unsigned(curr_index,10));
end behavioral;
