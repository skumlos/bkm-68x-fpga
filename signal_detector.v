module signal_detector (
	input clk_50mhz_in,
	input hsync_in,
	output signal_present_out);
	
reg [31:0] keepalive = 0;
reg signal_present = 1'b0;

reg last_hsync_in = 1'b1;

assign signal_present_out = signal_present;

parameter signal_present_threshold = 15000000;

always @ (posedge clk_50mhz_in) begin
	if(hsync_in != last_hsync_in) begin
		signal_present <= 1'b1;
		keepalive <= 0;
	end else begin
		keepalive <= keepalive + 1'b1;
		if(keepalive >= signal_present_threshold) begin
			keepalive <= signal_present_threshold;
			signal_present <= 1'b0;
		end else begin
			signal_present <= 1'b1;
		end
	end
	last_hsync_in <= hsync_in;
end

endmodule
