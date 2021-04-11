module video_format_detector(
	input clk_50mhz_in,
	input vsync_in,
	input hsync_in,
	output sample_out,
	output [4:0] error_bits,
	output [7:0] video_format);

localparam frq_hz = 50000000;

reg [31:0] hsync_cnt = 'h00;

reg reset = 1'b1;

reg [31:0] vsync_cnt = 'h0;
reg [31:0] vsync_frq = 'h0;

reg [31:0] clk_count = 'h0;
reg [4:0] error_b = 'h0;
reg [7:0] reg_format = 'h00;
reg interlaced = 1'b0;

assign video_format = reg_format;
assign sample_out = sample;
assign error_bits = error_b;

initial begin
	clk_count = 'h0;
	reset = 1'b1;

	vsync_cnt = 'h0;
	hsync_cnt = 'h0;
	vsync_frq = 'h0;

	error_b = 'h0;
	reg_format = 'h00;
	interlaced = 1'b0;
end

reg sample = 1'b1;

always @ (posedge clk_50mhz_in) begin
	clk_count <= clk_count + 1'b1;
	if(clk_count == frq_hz) begin
		sample <= 'b0;
		clk_count <= 'h0;
	end else begin
		sample <= 'b1;
	end
end

reg first_run = 1'b1;
reg [31:0] vsync_begin = 0;

always @ (posedge sample) begin
	if(first_run) begin
		vsync_begin <= vsync_cnt;
		first_run <= 1'b0;
		interlaced <= 1'b1;
		vsync_frq <= vsync_frq;
	end else begin
		vsync_frq <= vsync_cnt - vsync_begin;
		first_run <= 1'b1;
		interlaced <= 1'b1;
	end
end

always @ (vsync_frq, interlaced) begin
	if(vsync_frq != 'h00) begin
		if(vsync_frq <= 58) begin
			if(interlaced == 1'b1) begin
				reg_format <= 'h01; // 576i50
			end else begin
				reg_format <= 'h03; // 576p50
			end
		end else if(vsync_frq <= 68) begin
			if(interlaced == 1'b1) begin
				reg_format <= 'h02; // 480i60
			end else begin
				reg_format <= 'h04; // 480p60
			end
		end else begin
			reg_format <= 'h00; // dafuq
		end
	end else begin
		reg_format <= 'h00;
	end
end

/*
always @ (negedge reset) begin
	if(vsync_cnt < 30) begin
		vsync_frq <= 0;
	end else if(vsync_cnt <= 51) begin
		vsync_frq <= 50;
	end else if(vsync_cnt <= 61) begin
		vsync_frq <= 60;
	end else begin
		vsync_frq <= vsync_frq;
	end

	if(hsync_cnt > 25000) begin
		interlaced <= 1'b0;
	end else begin
		interlaced <= 1'b1;
	end
end
*/
always @ (negedge vsync_in, negedge reset) begin
	if(!reset) begin
		vsync_cnt <= 0;
	end else begin
		vsync_cnt <= vsync_cnt + 1'b1;
	end
end

always @ (negedge hsync_in, negedge reset) begin
	if(!reset) begin
		hsync_cnt <= 0;
	end else begin
		hsync_cnt <= hsync_cnt + 1'b1;
	end
end

endmodule