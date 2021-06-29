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
	output led1,
	output led2,
	output led3,
	output led4,
	output led5,
	input back_button1,
	input back_button2,
	input dip1,
	input dip2,
	input vsync_in,
	input hsync_in,
	input clk_in);

wire [7:0] video_format;

wire vsync_polarity;
wire hsync_polarity;

polarity_detector vsync_polarity_detector(
	.clk_50mhz_in(clk_in),
	.sync_in(vsync_in),
	.positive_polarity_out(vsync_polarity));

polarity_detector hsync_polarity_detector(
	.clk_50mhz_in(clk_in),
	.sync_in(hsync_in),
	.positive_polarity_out(hsync_polarity));

assign vsync_out = vsync_polarity ? vsync_in : ~vsync_in;
assign hsync_out = hsync_polarity ? hsync_in : ~hsync_in;

wire vsync_in_x = vsync_polarity ? ~vsync_in : vsync_in;
wire hsync_in_x = hsync_polarity ? ~hsync_in : hsync_in;

wire int_video_oe_x;
wire heartbeat_w;

reg video_oe_x_forced = 1'b0;
wire back_button1_filtered;

assign led1 = ~vsync_polarity;
assign led2 = ~hsync_polarity;

//assign led2 = ~video_oe_x_forced;
assign video_oe_x = video_oe_x_forced ? 1'b0 : int_video_oe_x;

always @ (negedge back_button1_filtered) begin
	video_oe_x_forced = ~video_oe_x_forced;
end

simplefilter button1_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button1),
	.sig_out(back_button1_filtered)
);

defparam button1_filter.FILTER_LEN = 20000;

wire int_int_ext_x;
wire back_button2_filtered;
reg int_ext_x_forced = 1'b1;

//assign led1 = video_oe_x_forced ? 1'b0 : heartbeat_w;
assign int_ext_x = video_oe_x_forced ? int_ext_x_forced : int_int_ext_x;

always @ (negedge back_button2_filtered) begin
	int_ext_x_forced = ~int_ext_x_forced;
end

simplefilter button2_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button2),
	.sig_out(back_button2_filtered)
);

defparam button2_filter.FILTER_LEN = 20000;

heartbeat hb(
	.clk_50mhz_in(clk_in),
	.heartbeat_out(heartbeat_w)
);

video_format_detector vf_det(
	.clk_50mhz_in(clk_in),
	.vsync_in(vsync_in_x),
	.hsync_in(hsync_in_x),
	.sample_out(hsync_pll_out),
	.video_format(video_format)
);

monitor_interface bkm68x_if(
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
	.video_oe_x(int_video_oe_x),
	.hd_sd_x(hd_sd_x),
	.rgb_comp_x(rgb_comp_x),
	.int_ext_x(int_int_ext_x),
	.video_format(video_format),
	.clk_50mhz_in(clk_in)
);
	
endmodule