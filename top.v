/* BKM-68X Alternative
 *
 * Version 1.1, see LICENSE
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
	output norm_y_g,
	output led1,
	output led2,
	input back_button1,
	input back_button2,
	input vsync_in,
	input hsync_in,
	input clk_in);

wire [7:0] video_format;
wire video_reset;
wire vsync_polarity;
wire hsync_polarity;
wire signal_present;
wire vsync_in_buf;
wire hsync_in_buf;
wire apt_on;
wire int_ext_x_;
wire vsync_in_x;
wire hsync_in_x;

reg normalize_y_g = 1'b0;

assign video_reset = ~signal_present;

assign norm_y_g = normalize_y_g;

// Invert int_ext_x (so its really int_x_ext) as this fits the BKM-68X Alternative board
assign int_ext_x = ~int_ext_x_;

assign vsync_in_buf = vsync_in;
assign hsync_in_buf = hsync_in;

// internal sync is always negative polarity, so no reason to take polarity detection into consideration
assign vsync_out = int_ext_x_ ? ~vsync_in_buf : (vsync_polarity ? vsync_in_buf : ~vsync_in_buf);
assign hsync_out = int_ext_x_ ? ~hsync_in_buf : (hsync_polarity ? hsync_in_buf : ~hsync_in_buf);
assign vsync_in_x = int_ext_x_ ? vsync_in_buf : (vsync_polarity ? ~vsync_in_buf : vsync_in_buf);
assign hsync_in_x = int_ext_x_ ? hsync_in_buf : (hsync_polarity ? ~hsync_in_buf : hsync_in_buf);

signal_detector sigdet(
	.clk_50mhz_in(clk_in),
	.hsync_in(hsync_in_buf),
	.signal_present_out(signal_present)
);

polarity_detector vsync_polarity_detector(
	.clk_50mhz_in(clk_in),
	.sync_in(vsync_in_buf),
	.reset(video_reset),
	.positive_polarity_out(vsync_polarity));

polarity_detector hsync_polarity_detector(
	.clk_50mhz_in(clk_in),
	.sync_in(hsync_in_buf),
	.reset(video_reset),
	.positive_polarity_out(hsync_polarity));

always @ (video_format,rgb_comp_x,int_ext_x,apt_on) begin
	// If the video format is HD, aka 720p/1080i, tri-level sync seems to be the go-to sync
	// method, which does not cause a DC offset, thus we do no need to "normalize" Y/G.
	// For SoG, we *do* (normally) need to remove it, as it will usually be bi-level sync.
	normalize_y_g = (rgb_comp_x == 1'b0 ? (((video_format > 'h05) & !apt_on) || apt_on) : (((int_ext_x == 1'b1) & !apt_on)) || apt_on);
end

wire heartbeat_w;

assign led1 = ((video_oe_x == 1'b0) ? heartbeat_w : 1'b0);
assign led2 = normalize_y_g;
//assign led1 = ~hsync_polarity;
//assign led2 = ~vsync_polarity;

/*
wire back_button1_filtered;

simplefilter button1_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button1),
	.sig_out(back_button1_filtered)
);
defparam button1_filter.FILTER_LEN = 500000;

always @ (negedge back_button1_filtered) begin
	// empty for now
end
*/

/*
wire back_button2_filtered;

simplefilter button2_filter(
	.clk_50mhz_in(clk_in),
	.sig_in(back_button2),
	.sig_out(back_button2_filtered)
);
defparam button2_filter.FILTER_LEN = 500000;

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
	.video_format(video_format)
);

monitor_interface bkm68x_if(
	.slot_x_int_x(~slot_x_int_x),
	.clk_rw(~clk_rw),
	.ax_d(~ax_d),
	.r_wx(~r_wx),
	.reset_x(~reset_x),
	.apt_on(apt_on),
	.int_x(irq_x),
	.int_oe_x(irq_oe_x),
	.data_in_x(ad),
	.data_out(ad_out),
	.data_oe_x(ad_oe_x),
	.video_oe_x(video_oe_x),
	.hd_sd_x(hd_sd_x),
	.rgb_comp_x(rgb_comp_x),
	.int_ext_x(int_ext_x_),
	.video_format(video_format),
	.clk_50mhz_in(clk_in)
);
	
endmodule