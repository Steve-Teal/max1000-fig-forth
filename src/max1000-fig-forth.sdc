#**************************************************************
# Create Clock
# Constrain clock port pclk with a 1-ns requirement
#**************************************************************
create_clock -name clk12m -period 83.333 -waveform {0 42} [get_ports clk12m]

derive_pll_clocks
derive_clock_uncertainty

# Constrain the input I/O path

set_input_delay -clock clk12m -max 3 [all_inputs]

set_input_delay -clock clk12m -min 2 [all_inputs]

# Constrain the output I/O path

set_output_delay -clock clk12m -max 3 [all_outputs]

set_output_delay -clock clk12m -min 2 [all_outputs]
