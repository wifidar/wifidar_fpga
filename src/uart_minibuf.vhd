library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity uart_minibuf is
	generic(
		num_samples: integer range 0 to 20000 := 20;
		sample_length_bits: integer range 0 to 32 := 14
	);
	port(
		data_in: in std_logic_vector (sample_length_bits -1 downto 0);
		
		data_out: out std_logic_vector(7 downto 0);

		index_data_in: out std_logic_vector(integer(ceil(log(real(num_samples))/log(real(2)))) downto 0);

		sample_buffer_full: in std_logic;
		uart_send_data: out std_logic;
		uart_ready: in std_logic;

		rst: in std_logic;
		clk: in std_logic
	);

end uart_minibuf;

architecture behavioral of uart_minibuf is

	type uart_minibuf_state is (reset,waiting,upper_half,upper_half_hold,lower_half,lower_half_hold);
	signal curr_state: uart_minibuf_state;

	signal curr_index: integer range 0 to (2**10)-1 := 0;

	signal uart_ready_prev: std_logic := '0';

	signal buffer_full_prev: std_logic := '0';
	signal end_buff: std_logic := '0';

begin
	process(clk,rst)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(clk)) then
			uart_ready_prev <= uart_ready;
			buffer_full_prev <= sample_buffer_full;

			if((buffer_full_prev = '1') and (sample_buffer_full = '0')) then
				end_buff <= '1';
			end if;

			case curr_state is
				when reset =>
					curr_state <= waiting;
				when waiting =>
					data_out <= (others => '0');
					curr_index <= 0;
					uart_send_data <= '0';
					if(sample_buffer_full = '1') then
						curr_state <= upper_half;
					end if;
				when upper_half =>
					if(curr_index = 0) then
						data_out <= "1" & data_in(13 downto 7);
					else
						data_out <= "0" & data_in(13 downto 7);
					end if;
					if(uart_ready = '1') then
						uart_send_data <= '1';
						curr_state <= upper_half_hold;
					end if;
				when upper_half_hold =>
					if(uart_ready = '0') then
						uart_send_data <= '0';
					end if;
					
					if(uart_ready = '1' and uart_ready_prev = '0') then
						curr_state <= lower_half;
					end if;
				when lower_half =>
					curr_index <= curr_index + 1;
					data_out <= "0" & data_in(6 downto 0);
					if(uart_ready = '1') then
						uart_send_data <= '1';
						curr_state <= lower_half_hold;
					end if;
				when lower_half_hold =>
					if(uart_ready = '0') then
						uart_send_data <= '0';
					end if;
					
					if(uart_ready = '1' and uart_ready_prev = '0') then
						curr_state <= upper_half;
					end if;
					
					if(end_buff = '1') then
						end_buff <= '0';
						curr_state <= waiting;
					end if;
			end case;
		end if;
	end process;

	index_data_in <= std_logic_vector(to_unsigned(curr_index,integer(ceil(log(real(num_samples))/log(real(2)))) + 1));
end behavioral;
