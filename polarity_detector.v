/*
 * BKM-68X Alternative Sync Polarity Detector
 * Determines the polarity of the sync, by counting the clock slices in low and high state.
 */

module polarity_detector(
	input clk_50mhz_in,
	input reset,
	input sync_in,
	output positive_polarity_out);

reg positive_polarity = 1'b0;

wire clk_1mhz;

Clock_divider clkdiv(
	.clock_in(clk_50mhz_in),
	.clock_out(clk_1mhz)
);
defparam clkdiv.DIVISOR=50;

// Add a glitch filter to avoid any spurious small deviations
glitch_filter gf(
	.clk(clk_1mhz),
	.in(positive_polarity),
	.out(positive_polarity_out));

defparam gf.FILTER_LEN = 16;

reg [31:0] cnt_pos = 32'd0;
reg [31:0] cnt_neg = 32'd0;
reg [31:0] cnt_pos_buf = 32'd0;
reg [31:0] cnt_neg_buf = 32'd0;
reg last_sync_level = 1'b0;
reg [3:0] counter = 4'd0;
reg cnt_clk_x = 1'b1;

always@(negedge clk_50mhz_in) begin
	if(reset) begin
		cnt_pos <= 32'd0;
		cnt_neg <= 32'd0;
		cnt_pos_buf <= 32'd0;
		cnt_neg_buf <= 32'd0;
		cnt_clk_x <= 1'b1;
	end else begin
		case ({ last_sync_level, sync_in })
			2'b00: begin
				cnt_neg <= cnt_neg + 'd1;
				cnt_clk_x <= 1'b1;
			end
			2'b10: begin // sync changed 1 -> 0
				cnt_pos_buf <= cnt_pos;
				cnt_neg <= 0;
				cnt_clk_x <= 1'b0;
			end
			2'b01: begin // sync changed 0 -> 1
				cnt_neg_buf <= cnt_neg;
				cnt_pos <= 0;
				cnt_clk_x <= 1'b0;
			end
			2'b11: begin
				cnt_pos <= cnt_pos + 'd1;
				cnt_clk_x <= 1'b1;
			end
		endcase
	end
	last_sync_level <= sync_in;
end

always@(negedge cnt_clk_x) begin
	if(reset) begin
		positive_polarity <= 'd0;
		counter = 'd0;
	end else begin
		if(cnt_neg_buf > cnt_pos_buf) begin
			if(!(&counter)) counter = counter + 4'd1;
		end else begin
			if(!(~|counter)) counter = counter - 4'd1;
		end
		if(&counter) positive_polarity <= 1'b1;
		else if(~|counter) positive_polarity <= 1'b0;
	end
end

endmodule