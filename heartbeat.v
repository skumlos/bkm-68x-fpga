module heartbeat(
	input clk_50mhz_in,
	output heartbeat_out
);

localparam frq_hz = 50000000;

reg [31:0] clk_count = 'h0;

reg heartbeat = 1'b0;

assign heartbeat_out = heartbeat;

always @ (posedge clk_50mhz_in) begin
	clk_count <= clk_count + 1'b1;
	if(clk_count == frq_hz) begin
		heartbeat <= ~heartbeat;
		clk_count <= 'h0;
	end
end

endmodule