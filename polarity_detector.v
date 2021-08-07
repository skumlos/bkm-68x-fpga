/*
 * BKM-68X Alternative Sync Polarity Detector
 * Determines the polarity of the sync, by counting the clock slices in low and high state.
 */
 
module polarity_detector(
	input clk_50mhz_in,
	input reset,
	input sync_in,
	output positive_polarity_out);

// assume we have a stable count after this number of level changes/edges
parameter sync_edge_threshold = 30;

reg positive_polarity = 1'b0;
reg stable = 1'b0;

assign positive_polarity_out = positive_polarity;

reg [31:0] cnt_pos = 32'd0;
reg [31:0] cnt_neg = 32'd0;
reg [31:0] cnt_pos_buf = 32'd0;
reg [31:0] cnt_neg_buf = 32'd0;
reg last_sync_level = 1'b0;
reg [7:0] pos_sync_edges = 1'd0;
reg [7:0] neg_sync_edges = 1'd0;

always@(negedge clk_50mhz_in) begin
	if(reset) begin
		cnt_pos <= 32'd0;
		cnt_neg <= 32'd0;
		cnt_pos_buf <= 32'd0;
		cnt_neg_buf <= 32'd0;
		pos_sync_edges <= 1'd0;
		neg_sync_edges <= 1'd0;
	end else begin
		case ({ last_sync_level, sync_in })
			2'b00: begin
				cnt_neg <= cnt_neg + 'd1;
			end
			2'b10: begin // sync changed 1 -> 0
				neg_sync_edges <= neg_sync_edges + 'd1;
				cnt_pos_buf <= cnt_pos;
				cnt_neg <= 0;
			end
			2'b01: begin // sync changed 0 -> 1
				pos_sync_edges <= pos_sync_edges + 'd1;
				cnt_neg_buf <= cnt_neg;
				cnt_pos <= 0;
			end
			2'b11: begin
				cnt_pos <= cnt_pos + 'd1;
			end
		endcase
	end
	last_sync_level <= sync_in;
end

always@(cnt_pos_buf,cnt_neg_buf,reset) begin
	if(reset) begin
		stable <= 1'b0;
	end else begin
		// we need to be sure that we've at least seen some
		// edges of each type before deciding on the polarity
		if((pos_sync_edges > sync_edge_threshold) &&
			(neg_sync_edges > sync_edge_threshold) && 
			(cnt_pos_buf > 0) && 
			(cnt_neg_buf > 0)) begin
			stable <= 1'b1;
		end else begin
			stable <= 1'b0;
		end
	end
end

always@(posedge stable) begin
		positive_polarity <= (cnt_neg_buf > cnt_pos_buf) ? 1'b1 : 1'b0;
end

endmodule