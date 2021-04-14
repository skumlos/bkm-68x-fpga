module video_format_detector(
	input clk_50mhz_in,
	input vsync_in,
	input hsync_in,
	output sample_out,
	output [7:0] video_format);

wire clk;

Clock_divider clk25mhz(
	.clock_in(clk_50mhz_in),
	.clock_out(clk),
);

wire vsync_filter;

simplefilter vs_filter(
	.clk_50mhz_in(clk_50mhz_in),
	.sig_in(vsync_in),
	.sig_out(vsync_filter)
);

defparam clk25mhz.DIVISOR = 28'd2;

localparam frq_hz = 50000000;

reg [31:0] hsync_cnt = 'h00;

reg reset = 1'b0;
reg has_reset = 1'b0;

reg [31:0] vsync_frq = 'h0;

reg [31:0] clk_count = 'h0;

reg [7:0] reg_format = 'h00;

reg interlaced = 1'b1;

wire vsync_count_clk = clk & vsync_filter;

assign video_format = reg_format;

assign sample_out = vsync_count_clk;

initial begin
	clk_count = 'h0;
	reset = 1'b0;
	has_reset = 1'b0;
	
	hsync_cnt = 'h0;
	vsync_frq = 'h0;

	reg_format = 'h00;
	interlaced = 1'b1;
end

always @ (posedge clk_50mhz_in) begin
	clk_count <= clk_count + 1'b1;
	if(clk_count == frq_hz) begin
		clk_count <= 'h0;
	end
end

always @ (negedge vsync_filter) begin
	if(vsync_frq == 50) begin
		if(interlaced == 1'b1) begin
			reg_format = 'h01; // 576i50
		end else begin
			reg_format = 'h03; // 576p50
		end
	end else if(vsync_frq == 60) begin
		if(interlaced == 1'b1) begin
			reg_format = 'h02; // 480i60
		end else begin
			reg_format = 'h04; // 480p60
		end
	end else begin
		reg_format = 'h00;
	end
end

/*
always @ (negedge reset) begin
	if(hsync_cnt > 17500) begin
		interlaced <= 1'b0;
	end else begin
		interlaced <= 1'b1;
	end
end
*/

always @ (posedge hsync_in, posedge reset) begin
	if(reset) begin
		hsync_cnt <= 0;
	end else begin
		hsync_cnt <= hsync_cnt + 1'b1;
	end
end

reg [31:0] clk_in_vsync_cnt = 0;

always @ (negedge vsync_filter) begin
	if(clk_in_vsync_cnt < 350000) begin
		vsync_frq = 0;
	end else if(clk_in_vsync_cnt < 425000) begin
		vsync_frq = 60;
	end else if(clk_in_vsync_cnt < 525000) begin
		vsync_frq = 50;
	end else begin
		vsync_frq = 0;
	end
end
/*
always @ (negedge vsync_in) begin
	if(clk_in_vsync_cnt < 70000) begin
		vsync_frq = 0;
	end else if(clk_in_vsync_cnt < 850000) begin
		vsync_frq = 60;
	end else if(clk_in_vsync_cnt < 1050000) begin
		vsync_frq = 50;
	end else begin
		vsync_frq = 0;
	end
end
*/
reg firstin = 1'b1;
always @ (negedge vsync_count_clk, negedge vsync_filter) begin
	if(!vsync_filter) begin
		firstin <= 1'b1;
		reset <= 1;
	end else begin
		if(firstin) begin
			clk_in_vsync_cnt <= 1;
			reset <= 0;
		end else begin
			clk_in_vsync_cnt <= clk_in_vsync_cnt + 1'b1;
			reset <= 0;
		end
		firstin <= 1'b0;
	end
end

endmodule