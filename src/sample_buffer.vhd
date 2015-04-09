library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sample_buffer is
	generic(
		sample_length_bits: integer range 0 to 32 := 12;
		num_samples: integer range 0 to 20000 := 500
	);
	port(
		sample_in: in std_logic_vector(sample_length_bits - 1 downto 0);
		sample_out: out std_logic_vector(sample_length_bits - 1 downto 0);

		sample_in_ready: in std_logic;

		sample_out_index: in std_logic_vector(ceil(log(num_samples)/log(2)) downto 0);
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

begin

	process(clk)
	begin
		if(rst = '1') then
			curr_state <= reset;
		elsif(rising_edge(clk)) then
			buffer_full_sig <= '0';
			case curr_state is
				when reset =>
					curr_state <= filling;
					buffer_full_sig <= '0';
					curr_input_address <= (others => '0');
				when filling =>
					if(sample_in_ready) then
						curr_input_address <= curr_input_addres + 1;
						if(curr_input_address = std_logic_vector(unsigned(num_samples))) then
							curr_input_address <= 0;
							curr_state <= emptying;
							buffer_full_sig <= '1';
						end if;
						sample_buffer_mem(curr_input_address) <= sample_in;
					end if;
				when emptying =>
					buffer_full_sig <= '1';
					if(sample_out_index = std_logic_vector(to_unsigned(num_samples,ceil(log(num_samples)/log(2))))) then
						curr_state <= filling;
						buffer_full_sig <= '0';
					end if;
					sample_out <= sample_buffer_mem(sample_out_index);
			end case;
		end if;
	end process;

	buffer_full <= buffer_full_sig;

end behavioral;
