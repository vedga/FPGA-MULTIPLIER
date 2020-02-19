#vlog -reportprogress 300 -sv -work work "+incdir+C:/Users/Monster/Documents/src/FPGA/VedgaE1-1.0" C:/Users/Monster/Documents/src/FPGA/VedgaE1-1.0/modules/ETHERNET/W5500/W5500_SPI.sv
vlog -reportprogress 300 -sv -work work "+incdir+C:/Users/Monster/Documents/src/FPGA/MUL" C:/Users/Monster/Documents/src/FPGA/MUL/MUL.sv
vsim work.MUL_testbench
add wave -position insertpoint -radix hexadecimal sim:/MUL_testbench/*

#add wave -position insertpoint sim:/MUL_testbench/mul/active

run 30000 ns
