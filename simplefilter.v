module simplefilter (
	input clk_50mhz_in,
	input sig_in,
	output sig_out);

parameter FILTER_LEN = 100; // 2us @ 50 MHz

reg filter = 1'b0;

assign sig_out = filter;

reg [31:0] filter_cnt;

initial begin
	filter_cnt = 0;
end

always @ (posedge clk_50mhz_in) begin
	if(sig_in != filter) begin
		filter_cnt <= filter_cnt + 1'b1;
		if(filter_cnt >= FILTER_LEN) begin
			filter <= sig_in;
		end
	end else begin
		filter_cnt <= 0;
	end
end

endmodule