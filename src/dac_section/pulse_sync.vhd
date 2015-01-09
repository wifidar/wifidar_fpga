library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_sync is

port(
        A: in std_logic;
        output: out std_logic;
        clk: in std_logic
		);
		  
end pulse_sync;

architecture Behavioral of pulse_sync is

 signal B: std_logic;
    signal C: std_logic;
    signal outB: std_logic;
    signal outC: std_logic;
    signal muxin: std_logic_vector (2 downto 0);
    signal muxout: std_logic_vector (1 downto 0);

begin

 process(clk)
    begin
        if(rising_edge(clk)) then
            B <= outB;
            C <= outC;
        end if;
    end process;
    muxin <= A & B & C;
    muxout <= outB & outC;

    with muxin select
        muxout <= "00" when "000",
            "00" when "001",
            "00" when "010",
            "01" when "100",
            "10" when "101",
            "10" when "110",
            "00" when others;
    outB <= muxout(1);
    outC <= muxout(0);
    output <= outC;

end Behavioral;

