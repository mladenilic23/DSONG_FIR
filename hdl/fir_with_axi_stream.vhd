library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity fir_with_axi_stream is
    generic( fir_ord : natural := 5;
             input_data_width : natural := 24;
             output_data_width : natural := 24;
             number_of_replication : natural := 5);
      
      port ( clk_i : in STD_LOGIC;
             we_i : in STD_LOGIC;
             rst_i : in STD_LOGIC;
             coef_addr_i : in std_logic_vector(log2c(fir_ord+1)-1 downto 0);
             coef_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
             --data_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
             --data_o : out STD_LOGIC_VECTOR (output_data_width-1 downto 0)
             
             --AXI Stream SLAVE
             S_AXIS_TREADY : out STD_LOGIC;
             S_AXIS_TDATA_in  : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
             S_AXIS_TVALID : in STD_LOGIC;
             S_AXIS_TLAST  : in STD_LOGIC;
             
             --AXI Stream MASTER
             M_AXIS_TREADY : in STD_LOGIC;
             M_AXIS_TDATA_out  : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
             M_AXIS_TVALID : out STD_LOGIC;
             M_AXIS_TLAST  : out STD_LOGIC
     );
end fir_with_axi_stream;

architecture Behavioral of fir_with_axi_stream is
    type state_type is (IDLE_SLAVE, IDLE_MASTER, SLAVE_READ, MASTER_WRITE, MASTER_LAST_WRITE);
    signal state_reg_slave : state_type;
    signal state_next_slave : state_type;
    signal state_reg_master: state_type; 
    signal state_next_master : state_type;
    
    signal S_AXIS_TDATA_in_s  : STD_LOGIC_VECTOR (input_data_width-1 downto 0) := (others => '0');
    signal M_AXIS_TDATA_out_s : STD_LOGIC_VECTOR (output_data_width-1 downto 0) := (others => '0');  

    signal tlast_counter_reg : std_logic_vector(log2c(fir_ord+1)-1 downto 0) := (others => '0');
    signal tlast_counter_next : std_logic_vector(log2c(fir_ord+1)-1 downto 0) := (others => '0');
    
    signal ce_i : std_logic;
begin

    fir_without_axi_stream:
    entity work.fir_param(Behavioral)
    generic map(fir_ord => fir_ord, 
                number_of_replication => number_of_replication, 
                input_data_width => input_data_width, 
                output_data_width => output_data_width
    )
    port map(
             clk_i => clk_i,
             ce_i  => ce_i,
             we_i  => we_i,
             coef_addr_i => coef_addr_i ,
             coef_i => coef_i,
             data_i => S_AXIS_TDATA_in_s,
             data_o => M_AXIS_TDATA_out_s
    ); 

    process(clk_i, rst_i)
    begin
        if(rising_edge(clk_i)) then
            if(rst_i = '1') then
                state_reg_slave <= IDLE_SLAVE;
                state_reg_master <= IDLE_MASTER;
                tlast_counter_reg <= (others => '0');
            else
                state_reg_slave <= state_next_slave;
                state_reg_master <= state_next_master;
                tlast_counter_reg <= tlast_counter_next;
            end if;
        end if;
    end process;   

    axi_stream_slave_input:
    process(state_reg_slave, S_AXIS_TVALID, S_AXIS_TDATA_in, S_AXIS_TLAST, M_AXIS_TREADY) is
    begin
        state_next_slave <= IDLE_SLAVE;
        S_AXIS_TREADY <= '0';
        
        case state_reg_slave is
            when IDLE_SLAVE =>
                if(S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') 
                then
                    S_AXIS_TREADY <= '1';
                    state_next_slave <= SLAVE_READ;
                else
                    state_next_slave <= IDLE_SLAVE;
                end if;
            when SLAVE_READ =>
                S_AXIS_TDATA_in_s <= S_AXIS_TDATA_in;  
                  
                if(S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') 
                then
                    S_AXIS_TREADY <= '1';
                
                    if(S_AXIS_TLAST = '1') 
                    then
                        state_next_slave <= IDLE_SLAVE;
                    else
                        state_next_slave <= SLAVE_READ;
                    end if;
                else
                    state_next_slave <= SLAVE_READ;
                end if;
            when others =>
                state_next_slave <= IDLE_SLAVE;
        end case;
    end process;

    axi_stream_slave_output:
    process(state_reg_master, state_reg_slave, S_AXIS_TVALID, M_AXIS_TREADY, M_AXIS_TDATA_out_s, S_AXIS_TLAST, tlast_counter_reg) is
    begin
        state_next_master <= IDLE_MASTER;
        M_AXIS_TVALID <= '0';
        M_AXIS_TLAST <= '0';
        tlast_counter_next <= (others => '0');
        --M_AXIS_TDATA_out <= (others => '0'); 
        ce_i <= '0';  

        case state_reg_master is
            when IDLE_MASTER =>
                if(state_reg_slave = SLAVE_READ and S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') 
                then
                    state_next_master <= MASTER_WRITE;
                else
                    state_next_master <= IDLE_MASTER;
                end if;
            when MASTER_WRITE =>
                M_AXIS_TDATA_out <= M_AXIS_TDATA_out_s;              
                if(S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
                    M_AXIS_TVALID <= '1';
                    ce_i <= '1';  
                    
                    if(S_AXIS_TLAST = '1') 
                    then
                        tlast_counter_next <= std_logic_vector(unsigned(tlast_counter_reg) + 1);
                        state_next_master  <= MASTER_LAST_WRITE;
                    else
                        tlast_counter_next <= tlast_counter_reg;
                        state_next_master  <= MASTER_WRITE;
                    end if;
                end if;
            when MASTER_LAST_WRITE =>
                M_AXIS_TVALID <= '1';
                M_AXIS_TDATA_out <= M_AXIS_TDATA_out_s;
                tlast_counter_next <= std_logic_vector(unsigned(tlast_counter_reg) + 1);

                if(tlast_counter_reg = std_logic_vector(to_unsigned(fir_ord, log2c(fir_ord + 1)) + 3)) 
                then
                    M_AXIS_TLAST <= '1';
                    state_next_master <= IDLE_MASTER;
                else
                    M_AXIS_TLAST <= '0';
                    state_next_master <= MASTER_LAST_WRITE;
                end if;
            when others =>
                state_next_master <= IDLE_MASTER;
        end case;
    end process;

end Behavioral;