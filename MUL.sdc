set_time_format -unit ns -decimal_places 3
# Тактовая частота 50Mhz, (50/50 duty cycle)
#create_clock -name SYSCLK -period 20.000  -waveform { 0.000 10.000 } [get_ports {clk}]
create_clock -name SYSCLK -period 6.000 [get_ports {clk}]

##############################################################################  Now that we have created the custom clocks which will be base clocks,#  derive_pll_clock is used to calculate all remaining clocks for PLLs
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

set_false_path -from [get_ports {ena a[*] b[*]}]
set_false_path -to [get_ports {accepted done complete out[*]}]