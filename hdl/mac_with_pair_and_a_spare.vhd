library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity mac_with_pair_and_a_spare is
    generic(input_data_width : natural :=24;
            number_of_replication : natural := 5);
       
    port(   clk_i : in std_logic;
            ce_i  : in std_logic;
            u_i   : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
            b_i   : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
            sec_i : in STD_LOGIC_VECTOR (2*input_data_width-1 downto 0);
            sec_o : out STD_LOGIC_VECTOR (2*input_data_width-1 downto 0));
end mac_with_pair_and_a_spare;

architecture Behavioral of mac_with_pair_and_a_spare is

    type data_to_mux is array(0 to number_of_replication-1) of STD_LOGIC_VECTOR(2*input_data_width downto 0);

    signal data_to_muxes : data_to_mux :=(others=>(others=>'0'));
    
    signal to_mux1 : data_to_mux :=(others=>(others=>'0'));
    signal to_mux2 : data_to_mux :=(others=>(others=>'0'));

    signal from_mux1 : STD_LOGIC_VECTOR(2*input_data_width downto 0) := (others=>'0');
    signal from_mux2 : STD_LOGIC_VECTOR(2*input_data_width downto 0) := (others=>'0');
    
    signal from_mux_to_output : STD_LOGIC_VECTOR(2*input_data_width-1 downto 0) := (others=>'0');

    signal sel_mux1 : STD_LOGIC_VECTOR(log2c(number_of_replication)-1 downto 0) := std_logic_vector(to_unsigned(0, log2c(number_of_replication)));
    signal sel_mux2 : STD_LOGIC_VECTOR(log2c(number_of_replication)-1 downto 0) := std_logic_vector(to_unsigned(0, log2c(number_of_replication)));

    signal error_from_first_comparator : STD_LOGIC := '0';

    signal counter : unsigned (log2c(number_of_replication) - 1 downto 0) := (to_unsigned(1, log2c(number_of_replication)));
    signal limit_for_counter : unsigned (log2c(number_of_replication) - 1 downto 0) := (to_unsigned(number_of_replication, log2c(number_of_replication)));

    signal sec_o_s : STD_LOGIC_VECTOR(2*input_data_width-1 downto 0) := (others => '0');

    attribute dont_touch : string;                                    
    attribute dont_touch of to_mux1 : signal is "true";
    attribute dont_touch of to_mux2 : signal is "true";
    attribute dont_touch of sel_mux1 : signal is "true"; 
    attribute dont_touch of sel_mux2 : signal is "true";
    attribute dont_touch of data_to_muxes : signal is "true";
begin
    mac_redudantion: 
    for i in 0 to number_of_replication-1 generate
        replication:
        entity work.two_mac_with_compare
        generic map(input_data_width => input_data_width)
        port map(
                clk_i => clk_i,
                ce_i  => ce_i,
                u_i   => u_i,
                b_i   => b_i,
                sec_i => sec_i,
                sec_o => data_to_muxes(i)(2*input_data_width downto 1),
                error_o => data_to_muxes(i)(0)
        );
    end generate;

    to_mux1(0) <=  data_to_muxes(0);
    assigning_value_for_mux1: 
    for i in 1 to number_of_replication-2 generate
        to_mux1(i) <=  data_to_muxes(i+1);
    end generate;
    
    assigning_value_for_mux2: 
    for i in 0 to number_of_replication-2 generate
        to_mux2(i) <=  data_to_muxes(i+1);
    end generate;

    from_mux1 <= to_mux1(to_integer(unsigned(sel_mux1(log2c(number_of_replication)-1 downto 0))));
    
    from_mux2 <= to_mux2(to_integer(unsigned(sel_mux2(log2c(number_of_replication)-1 downto 0))));
    
    
    process(clk_i, error_from_first_comparator, from_mux1(0), from_mux1(0), sel_mux1, sel_mux2, counter) 
    begin
        if(rising_edge(clk_i)) then
            if((error_from_first_comparator = '1' and from_mux1(0) = '1') and sel_mux1 /= std_logic_vector(counter) and counter < limit_for_counter) then  
                sel_mux1 <= std_logic_vector(counter);
                counter <= counter + 1;
            elsif((error_from_first_comparator = '1' and from_mux2(0) = '1') and sel_mux2 /= std_logic_vector(counter) and counter < limit_for_counter) then  
                sel_mux2 <= std_logic_vector(counter);
                counter <= counter + 1;
            else
                counter <= counter;
            end if;
        end if;
    end process;
    
    process(from_mux1(2*input_data_width downto 1), from_mux2(2*input_data_width downto 1))
    begin
        if(from_mux1(2*input_data_width downto 1) /= from_mux2(2*input_data_width downto 1)) then
            error_from_first_comparator <= '1';
        else
            error_from_first_comparator <= '0';
        end if;
    end process;
    
    process(from_mux1, from_mux2)
    begin
        if(from_mux1(0) = '0') then
            from_mux_to_output <= from_mux1(2*input_data_width downto 1);
        else
            from_mux_to_output <= from_mux2(2*input_data_width downto 1);
        end if;   
    end process;
    
    process(counter, limit_for_counter, from_mux1(2*input_data_width downto 1)) 
    begin
        if(counter = limit_for_counter) then
            sec_o <= (others => '0');
        else
            sec_o <= from_mux_to_output;
        end if;
    end process;
    
end Behavioral;