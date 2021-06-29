module polarity_detector(
	input clk_50mhz_in,
	input sync_in,
	output positive_polarity_out);

reg positive_polarity = 1'b0;

assign positive_polarity_out = positive_polarity;

reg [31:0] cnt_pos = 32'd0;
reg [31:0] cnt_neg = 32'd0;
reg [31:0] cnt_pos_buf = 32'd0;
reg [31:0] cnt_neg_buf = 32'd0;
reg last_sync_level = 1'b0;

always@(negedge clk_50mhz_in) begin
		case ({ last_sync_level, sync_in })
			2'b00: begin
				cnt_neg <= cnt_neg + 'd1;
			end
			2'b10: begin // sync changed 1 -> 0
				cnt_pos_buf = cnt_pos;
				cnt_neg <= 0;
			end
			2'b01: begin // sync changed 0 -> 1
				cnt_neg_buf = cnt_neg;
				cnt_pos <= 0;
			end
			2'b11: begin
				cnt_pos <= cnt_pos + 'd1;
			end
		endcase
		last_sync_level <= sync_in;
		positive_polarity <= (cnt_neg_buf > cnt_pos_buf) ? 1'b1 : 1'b0;
end

endmodule