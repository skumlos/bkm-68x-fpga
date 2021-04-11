module top(	
	input slot_x_int_x,
	input clk_rw,
	input ax_d,
	input reset_x,
	input r_wx,
	input [7:0] ad,
	output [7:0] ad_out,
	output irq_oe_x,
	output ad_oe_x,
	output irq_x,
	output hd_sd_x,
	output rgb_comp_x,
	output int_ext_x,
	output video_oe_x,
	output vsync_out,
	output hsync_out,
	output hsync_pll_out,
	output led1,
	output led2,
	output led3,
	output led4,
	output led5,
	input back_button,
	input dip1,
	input dip2,
	input vsync_in,
	input hsync_in,
	input clk_in,
	output clk_out);

wire [7:0] video_format;
assign vsync_out = ~vsync_in;
assign hsync_out = ~hsync_in;

assign led1 = ~video_format[0];
assign led2 = ~video_format[1];
assign led3 = ~video_format[2];
assign led4 = ~video_format[3];
assign led5 = ~video_format[4];

wire clk_pll;

Clock_divider clkdiv(.clock_in(clk_in),.clock_out(clk_pll));

heartbeat hb(
	.clk_50mhz_in(clk_in),
//	.heartbeat_out(led1)
);

video_format_detector vf_det(
	.clk_50mhz_in(clk_in),
	.vsync_in(vsync_in),
	.hsync_in(hsync_in),
	.sample_out(hsync_pll_out),
	.video_format(video_format)
);

monitor_interface2 bkm68x_if(
	.slot_x_int_x(~slot_x_int_x),
	.clk_rw(~clk_rw),
	.ax_d(~ax_d),
	.r_wx(~r_wx),
	.reset_x(~reset_x),
	.int_x(irq_x),
	.int_oe_x(irq_oe_x),
	.data_in_x(ad),
	.data_out(ad_out),
	.data_oe_x(ad_oe_x),
	.video_oe_x(video_oe_x),
	.hd_sd_x(hd_sd_x),
	.rgb_comp_x(rgb_comp_x),
	.int_ext_x(int_ext_x),
	.video_format(video_format),
	.skip_init(back_button),
	.clk_50mhz_in(clk_in)
);
	
endmodule