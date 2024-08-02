library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity two_mac_with_compare is
    generic (input_data_width : natural :=24);
      
    port(   
        clk_i : in std_logic;
        ce_i  : in std_logic;
        u_i   : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
        b_i   : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
        sec_i : in STD_LOGIC_VECTOR (2*input_data_width-1 downto 0);
        sec_o : out STD_LOGIC_VECTOR (2*input_data_width-1 downto 0);
        error_o : out STD_LOGIC        
    );
end two_mac_with_compare;

architecture Behavioral of two_mac_with_compare is
    signal mac_out1 : STD_LOGIC_VECTOR(2*input_data_width-1 downto 0) := (others => '0');
    signal mac_out2 : STD_LOGIC_VECTOR(2*input_data_width-1 downto 0)  := (others => '0');
    signal sec_o_s : STD_LOGIC_VECTOR(2*input_data_width-1 downto 0)  := (others => '0');
    signal error_o_s : STD_LOGIC := '0';

    attribute dont_touch : string;                  
    attribute dont_touch of mac_out1 : signal is "true";                  
    attribute dont_touch of mac_out2 : signal is "true"; 
begin

    FIRST_MAC:
    entity work.mac(Behavioral)
    generic map(input_data_width => input_data_width)
    port map(
            clk_i => clk_i,
            ce_i  => ce_i,
            u_i   => u_i,
            b_i   => b_i,
            sec_i => sec_i,
            sec_o => mac_out1);
            
    SECOND_MAC:
    entity work.mac(Behavioral)
    generic map(input_data_width => input_data_width)
    port map(
            clk_i => clk_i,
            ce_i  => ce_i,
            u_i   => u_i,
            b_i   => b_i,
            sec_i => sec_i,
            sec_o => mac_out2);

    FAULT_DETECTION:
    process(mac_out1, mac_out2)
    begin
        --if(rising_edge(clk_i)) then
            if(mac_out1 /= mac_out2) then
                error_o <= '1';
                sec_o <= mac_out1;
            else
                error_o <= '0';
                sec_o <= mac_out1;
            end if;
        --end if;
    end process;

    --sec_o   <= sec_o_s;
    --error_o <= error_o_s;
end Behavioral;