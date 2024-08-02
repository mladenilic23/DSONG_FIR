cd ..
set root_dir [pwd]
cd scripts
set resultDir ../vivado_project

file mkdir $resultDir

create_project vivado_project $resultDir -part xc7z020clg400-1
set_property board_part digilentinc.com:zybo-z7-20:part0:1.0 [current_project]

add_files -norecurse ../hdl/util_pkg.vhd
add_files -norecurse ../hdl/txt_util.vhd
add_files -norecurse ../hdl/mac.vhd
add_files -norecurse ../hdl/two_mac_with_compare.vhd
add_files -norecurse ../hdl/mac_with_pair_and_a_spare.vhd
add_files -norecurse ../hdl/fir_param.vhd
add_files -norecurse ../hdl/fir_with_axi_stream.vhd

update_compile_order -fileset sources_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]

#add_files -fileset sim_1 -norecurse ../testbench/tb_without_axi.vhd
#add_files -fileset sim_1 -norecurse ../testbench/tb_mac_with_pair_and_a_spare.vhd
add_files -fileset sim_1 -norecurse ../testbench/tb_with_axi.vhd

#add_files -fileset sim_1 -norecurse ../waveform_config/tb_mac_with_pair_and_a_spare_behav.wcfg
#add_files -fileset sim_1 -norecurse ../waveform_config/tb_without_axis_behav.wcfg
add_files -fileset sim_1 -norecurse ../waveform_config/tb_with_axi_behav.wcfg

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1