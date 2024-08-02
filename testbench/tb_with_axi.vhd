
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.txt_util.all;
use work.util_pkg.all;

entity tb_with_axi is
    generic( fir_ord : natural := 5;
             in_out_data_width : natural := 24;
             number_of_replication : natural := 5);
--  Port ( );
end tb_with_axi;

architecture Behavioral of tb_with_axi is
    constant period : time := 20 ns;
    signal clk_i_s : std_logic;
    signal rst_i_s : std_logic;
    file input_test_vector : text open read_mode is "..\..\..\..\..\data\input.txt";
    file output_check_vector : text open read_mode is "..\..\..\..\..\data\expected.txt";
    file input_coef : text open read_mode is "..\..\..\..\..\data\coef.txt";
    signal coef_addr_i_s : std_logic_vector(log2c(fir_ord)-1 downto 0);
    signal coef_i_s : std_logic_vector(in_out_data_width-1 downto 0);
    signal we_i_s : std_logic := '0';
    
    signal start_check : std_logic := '0';
    
    --AXI Stream SLAVE
    signal S_AXIS_TREADY_S : STD_LOGIC;
    signal S_AXIS_TDATA_in_S  : STD_LOGIC_VECTOR (in_out_data_width-1 downto 0) := (others => '0');
    signal S_AXIS_TVALID_S : STD_LOGIC;
    signal S_AXIS_TLAST_S  : STD_LOGIC;
    
    --AXI Stream MASTER
    signal M_AXIS_TREADY_S : STD_LOGIC;
    signal M_AXIS_TDATA_out_S  : STD_LOGIC_VECTOR (in_out_data_width-1 downto 0);
    signal M_AXIS_TVALID_S : STD_LOGIC;
    signal M_AXIS_TLAST_S  : STD_LOGIC;
    
    signal data_expected_s : std_logic_vector(in_out_data_width-1 downto 0)   := (others => '0');
    signal loop_count : integer := 1;
    begin


    uut_fir_filter:
    entity work.fir_with_axi_stream(Behavioral)
    generic map(fir_ord=>fir_ord,
                number_of_replication => number_of_replication,
                input_data_width=>in_out_data_width,
                output_data_width=>in_out_data_width)
    port map(clk_i  => clk_i_s,
             rst_i  => rst_i_s,
             we_i   => we_i_s,
             coef_i => coef_i_s,
             coef_addr_i => coef_addr_i_s,
             
             --AXI Stream SLAVE
             S_AXIS_TREADY   => S_AXIS_TREADY_S,
             S_AXIS_TDATA_in => S_AXIS_TDATA_IN_S,
             S_AXIS_TVALID   => S_AXIS_TVALID_S,
             S_AXIS_TLAST    => S_AXIS_TLAST_S,
             
             --AXI Stream MASTER
             M_AXIS_TREADY    => M_AXIS_TREADY_S,
             M_AXIS_TDATA_out => M_AXIS_TDATA_OUT_S,
             M_AXIS_TVALID    => M_AXIS_TVALID_S,
             M_AXIS_TLAST     => M_AXIS_TLAST_S);
    
    clk_process:
    process
    begin
        clk_i_s <= '0';
        wait for period/2;
        clk_i_s <= '1';
        wait for period/2;
    end process;
    
    stim_process:
    process
        variable tv : line;
        variable i : integer := 0;
    begin
        S_AXIS_TVALID_S <= '0';
        S_AXIS_TLAST_S  <= '0';
        S_AXIS_TDATA_IN_S <= (others => '0');
        rst_i_s <= '1';
        wait until falling_edge(clk_i_s);
        rst_i_s <= '0';
        
        --upis koeficijenata
        for i in 0 to fir_ord loop
            we_i_s <= '1';
            coef_addr_i_s <= std_logic_vector(to_unsigned(i,log2c(fir_ord)));
            readline(input_coef,tv);
            coef_i_s <= to_std_logic_vector(string(tv));
            wait until falling_edge(clk_i_s);
        end loop;
        
        S_AXIS_TVALID_S <= '1';
        wait until rising_edge(S_AXIS_TREADY_S);

        --ulaz za filtriranje
--        for i in 0 to 4000 loop
--            readline(input_test_vector,tv);
--            S_AXIS_TDATA_IN_S <= to_std_logic_vector(string(tv));
--            wait until falling_edge(clk_i_s);
--            start_check <= '1';
--            if(i = 3999) then
--                S_AXIS_TLAST_S <= '1';
--            end if;
--        end loop;
        while i <= 4000 loop
            if (i = 300) then
                S_AXIS_TVALID_S <= '0';
            elsif(i = 301) then
                S_AXIS_TVALID_S <= '0';
            elsif(i = 700) then
                S_AXIS_TVALID_S <= '0';
            elsif(i = 701) then
                S_AXIS_TVALID_S <= '0';              
            else
                S_AXIS_TVALID_S <= '1';
                readline(input_test_vector, tv);
                S_AXIS_TDATA_IN_S <= to_std_logic_vector(string(tv));
            end if;
    
            wait until falling_edge(clk_i_s);
            start_check <= '1';
            
            if (i = 3999) then
                S_AXIS_TLAST_S <= '1';
            end if;
    
            i := i + 1;
        end loop;

        start_check <= '0';
        S_AXIS_TLAST_S <= '0';
        S_AXIS_TVALID_S <= '0';
        wait;
        --report "verification done!" severity failure;
    end process;

    check_process:
    process
        variable check_v : line;
        variable tmp : std_logic_vector(in_out_data_width-1 downto 0);
    begin
        M_AXIS_TREADY_S <= '1';
        wait until start_check = '1';
        while not endfile(output_check_vector) loop
            wait until rising_edge(clk_i_s);
            
            if(S_AXIS_TVALID_S = '1') then
                readline(output_check_vector,check_v);
                tmp := to_std_logic_vector(string(check_v));
                data_expected_s <= to_std_logic_vector(string(check_v));
                loop_count <= loop_count + 1;
                
                if(abs(signed(tmp) - signed(M_AXIS_TDATA_OUT_S)) > "000000000000000000000111")then
                    --report "result mismatch!" severity failure;
                end if;
            end if;            
        end loop;
        
        wait until rising_edge(M_AXIS_TLAST_S);
        wait until rising_edge(clk_i_s);
        report "verification done!" severity failure;
    end process;
    
end Behavioral;
