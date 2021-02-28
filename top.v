module top(	
	input slot_x_int_x,
	input clk_rw,
	input ax_d,
	input reset_x,
	input r_wx,
	input [7:0] ad,
	input [7:0] ad_out,
	output hd_sd_x,
	output rgb_comp_x,
	output int_ext_x,
	output irq_oe_x,
	output ad_oe_x,
	output irq_x,
	output video_oe_x,
	input clk_in);

monitor_interface bkm68x_if(.slot_x(slot_x_int_x),
	.clk_rw(clk_rw),
	.ax_d(ax_d),
	.r_wx(r_wx),
	.reset_x(reset_x),
	.int_x(irq_x),
	.int_oe_x(irq_oe_x),
	.data_in(ad),
	.data_out(ad_out),
	.data_oe_x(ad_oe_x),
	.clk_20mhz(clk_in));
	
endmodule