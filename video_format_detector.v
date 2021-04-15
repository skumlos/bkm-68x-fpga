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
wire hsync_filter;

simplefilter vs_filter(
	.clk_50mhz_in(clk_50mhz_in),
	.sig_in(vsync_in),
	.sig_out(vsync_filter)
);

simplefilter hs_filter(
	.clk_50mhz_in(clk_50mhz_in),
	.sig_in(hsync_in),
	.sig_out(hsync_filter)
);

defparam clk25mhz.DIVISOR = 28'd2;

localparam frq_hz = 50000000;

reg [31:0] hsync_cnt = 'h00;

reg [31:0] vsync_frq = 'h0;

reg [31:0] clk_count = 'h0;

reg [7:0] reg_format = 'h00;

wire vsync_count_clk = clk & vsync_filter;
wire hsync_count_clk = hsync_filter & vsync_filter;

assign video_format = reg_format;

assign sample_out = hsync_count_clk;

initial begin
	clk_count = 'h0;
	
	hsync_cnt = 'h0;
	vsync_frq = 'h0;

	reg_format = 'h00;
end

always @ (posedge clk_50mhz_in) begin
	clk_count <= clk_count + 1'b1;
	if(clk_count == frq_hz) begin
		clk_count <= 'h0;
	end
end

reg hs_firstin = 1'b1;
always @ (negedge hsync_count_clk, negedge vsync_filter) begin
	if(!vsync_filter) begin
		hs_firstin <= 1'b1;
	end else begin
		if(hs_firstin) begin
			hsync_cnt <= 1;
		end else begin
			hsync_cnt <= hsync_cnt + 1'b1;
		end
		hs_firstin <= 1'b0;
	end
end

always @ (negedge vsync_filter) begin
	if(vsync_frq == 50) begin
		if(hsync_cnt < 380) begin
			reg_format = 'h01; // 576i50
		end else if(hsync_cnt < 550) begin
			reg_format = 'h0B; // 1080i50, unverified
		end else if(hsync_cnt < 590) begin
			reg_format = 'h03; // 576p50
		end else if(hsync_cnt < 740) begin
			reg_format = 'h12; // 720p50, unverified
		end else begin
			reg_format = 'h00; // sum-ting-wong
		end
	end else if(vsync_frq == 60) begin
		if(hsync_cnt < 300) begin
			reg_format = 'h02; // 480i60
		end else if(hsync_cnt < 500) begin
			reg_format = 'h04; // 480p60
		end else if(hsync_cnt < 560) begin
			reg_format = 'h0C; // 1080i60
		end else if(hsync_cnt < 740) begin
			reg_format = 'h13; // 720p60
		end else begin
			reg_format = 'h00; // sum-ting-wong
		end
	end else begin
		reg_format = 'h00;
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


reg firstin = 1'b1;
always @ (negedge vsync_count_clk, negedge vsync_filter) begin
	if(!vsync_filter) begin
		firstin <= 1'b1;
	end else begin
		if(firstin) begin
			clk_in_vsync_cnt <= 1;
		end else begin
			clk_in_vsync_cnt <= clk_in_vsync_cnt + 1'b1;
		end
		firstin <= 1'b0;
	end
end

endmodule