# Constrain clock port clk_rw with a 20-ns (50MHz) requirement
create_clock -period 20 [get_ports clk_rw]

# Constrain clock port clk_in with a 10-ns (100MHz) requirement
create_clock -period 10 [get_ports clk_in]

create_clock -period 1000 [get_ports vsync_in]
create_clock -period 400 [get_ports hsync_in]
#create_clock -name {video_format_detector:vf_det|sample} -period 10.000
#create_clock -period 10 {video_format_detector:vf_det|reset}
#create_clock -period 10 {video_format_detector:vf_det|vsync_count_clk}

# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design

derive_pll_clocks

# Constrain the input I/O path
set_input_delay -clock clk_rw -max 3 [all_inputs]
set_input_delay -clock clk_rw -min 2 [all_inputs]

# Constrain the output I/O path
set_output_delay -clock clk_rw -max 3 [all_outputs]
set_output_delay -clock clk_rw -min 2 [all_outputs]

set_output_delay -clock vsync_in -max 2 [get_ports vsync_out]
set_output_delay -clock vsync_in -min 1 [get_ports vsync_out]
set_output_delay -clock hsync_in -max 2 [get_ports hsync_out]
set_output_delay -clock hsync_in -min 1 [get_ports hsync_out]

derive_clock_uncertainty