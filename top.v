/* BKM-68X Alternative
 *
 * Version 1.0, see LICENSE
 *
 * See https://www.immerhax.com for more information
 *
 * (2021) Martin Hejnfelt (martin@hejnfelt.com)
 */

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
	input back_button1,
	input back_button2,
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

wire heartbeat_w;

assign led1 = ((video_oe_x == 1'b0) ? 1'b0 : heartbeat_w);
assign led2 = int_ext_x;

/*
wire back_button1_filtered;
wire back_button2_filtered;

simplefilter button1_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button1),
	.sig_out(back_button1_filtered)
);
defparam button1_filter.FILTER_LEN = 20000;

simplefilter button2_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button2),
	.sig_out(back_button2_filtered)
);
defparam button2_filter.FILTER_LEN = 20000;

always @ (negedge back_button1_filtered) begin
	// empty for now
end

always @ (negedge back_button2_filtered) begin
	// empty for now
end
*/

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
	.video_oe_x(video_oe_x),
	.hd_sd_x(hd_sd_x),
	.rgb_comp_x(rgb_comp_x),
	.int_ext_x(int_ext_x),
	.video_format(video_format),
	.clk_50mhz_in(clk_in)
);
	
endmodule