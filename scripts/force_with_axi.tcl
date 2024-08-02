# Ukljanjanje forsiranih vrednosti
remove_forces { {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(0)\/replication/mac_out1} }
remove_forces { {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(1)\/replication/mac_out1} }
remove_forces { {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(2)\/replication/mac_out1} }
remove_forces { {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(3)\/replication/mac_out1} }
remove_forces { {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(4)\/replication/mac_out1} }

# Forsiranje vrednosti na odredjenim portovima 
# Po potrebi zakomentarisati/otkomentarisati liniju sa "#" 
# ukoliko zelite manje/vise da dovedete u stanje kvara
add_force {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(0)\/replication/mac_out1} -radix hex {1 400ns} -cancel_after 500ns
add_force {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(1)\/replication/mac_out1} -radix hex {1 500ns} -cancel_after 600ns
#add_force {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(2)\/replication/mac_out1} -radix hex {1 600ns} -cancel_after 700ns
#add_force {/tb_with_axi/uut_fir_filter/fir_without_axi_stream/first_section/\mac_redudantion(3)\/replication/mac_out1} -radix hex {1 700ns} -cancel_after 800ns


