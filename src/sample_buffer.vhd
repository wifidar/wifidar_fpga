library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity sample_buffer is
	generic(
		num_samples: integer range 0 to 20000 := 400;
		sample_length_bits: integer range 0 to 32 := 14
	);
	port(
		sample_in: in std_logic_vector(sample_length_bits - 1 downto 0);
		sample_out: out std_logic_vector(sample_length_bits - 1 downto 0);

		sample_in_ready: in std_logic;
		initial_sample: in std_logic;

		sample_out_index: in std_logic_vector(integer(ceil(log(real(num_samples))/log(real(2)))) downto 0);
		buffer_full: out std_logic;
		
		rst: in std_logic;
		clk: in std_logic
	);

end sample_buffer;

architecture behavioral of sample_buffer is


	type sample_buffer_mem_type is array (0 to (num_samples - 1)) of std_logic_vector(sample_length_bits - 1 downto 0);
	signal sample_buffer_mem: sample_buffer_mem_type;

	type sample_buffer_state is (reset,filling,emptying);
	signal curr_state: sample_buffer_state;

	signal curr_input_address: integer range 0 to num_samples := 0;
	signal buffer_full_sig: std_logic := '0';
	signal initialized: std_logic := '0';
	
	signal initial_sample_prev: std_logic;

begin

	process(clk,rst)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(clk)) then
			initial_sample_prev <= initial_sample;
			buffer_full_sig <= '0';
			case curr_state is
				when reset =>
					curr_state <= filling;
					buffer_full_sig <= '0';
					curr_input_address <= 0;
				when filling =>
					if(initial_sample_prev = '1' and initial_sample = '0') then
						initialized <= '1';
						curr_input_address <= 0;
					end if;
					if(sample_in_ready = '1' and initialized = '1') then
						curr_input_address <= curr_input_address + 1;
						if(curr_input_address = num_samples) then
							curr_input_address <= 0;
							curr_state <= emptying;
							buffer_full_sig <= '1';
						else
							sample_buffer_mem(curr_input_address) <= std_logic_vector(signed(sample_in) + (2**13));
						end if;
					end if;
				when emptying =>
					initialized <= '0';
					buffer_full_sig <= '1';
					if(sample_out_index = std_logic_vector(to_unsigned(num_samples,sample_out_index'length))) then
						curr_state <= filling;
						buffer_full_sig <= '0';
						sample_out <= (others => '0');
					else
						sample_out <= sample_buffer_mem(to_integer(unsigned(sample_out_index)));
					end if;
			end case;
		end if;
	end process;

	buffer_full <= buffer_full_sig;

end behavioral;
