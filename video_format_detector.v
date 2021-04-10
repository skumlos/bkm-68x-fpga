module video_format_detector(
	input clk_50mhz_in,
	input vsync_in,
	input hsync_in,
	output [7:0] video_format);

reg [31:0] horiz_during_vsync_pos = 'h00;
reg [31:0] horiz_during_vsync_neg = 'h00;
reg [31:0] horiz_during_vsync = 'h00;

reg sample = 1'b1;

reg last_vsync_state = 'b0;
reg [31:0] vsync_cnt = 'h0;

reg [31:0] vsync_frq = 'h0;

localparam frq_hz = 50000000;

reg [31:0] clk_count = 'h0;

reg [7:0] reg_format = 'h00;

assign video_format = reg_format;
/*
always @ (vsync_frq, horiz_during_vsync) begin
	if(vsync_frq != 0 && horiz_during_vsync != 0) begin
		if(vsync_frq < 52) begin
			if(horiz_during_vsync < 320) begin
				reg_format <= 'h01; // 576i50
			end else if (horiz_during_vsync < 630) begin
				reg_format <= 'h03; // 576p50
			end else begin
				reg_format <= 'h00; // dafuq
			end
		end else if(vsync_frq < 62) begin
			if(horiz_during_vsync < 320) begin
				reg_format <= 'h02; // 480i60
			end else if (horiz_during_vsync < 530) begin
				reg_format <= 'h04; // 480p60
			end else begin
				reg_format <= 'h00; // dafuq
			end
		end else begin
			reg_format <= 'h0; // dafuq
		end
	end else begin
		reg_format <= 'h0;
	end
end
*/

always@(vsync_frq) begin
	if(vsync_frq != 'h00) begin
		reg_format <= 'h02;
	end else begin
		reg_format <= 'h00;
	end
end

always @ (posedge clk_50mhz_in) begin
//	if(clk_50mhz_in == 1'b1) begin
		if(clk_count < frq_hz) begin
			clk_count <= clk_count + 1'b1;
			sample <= 'b1;
		end else begin
			clk_count <= 'h0;
			vsync_frq <= vsync_cnt;
			sample <= 'b0;
		end
//	end
end

always @ (negedge vsync_in, negedge sample) begin
	if(!sample) begin
		vsync_cnt <= 0;
	end else begin
		vsync_cnt <= vsync_cnt + 1'b1;
	end
end

always @ (negedge hsync_in) begin
	if(last_vsync_state != vsync_in) begin
		if(horiz_during_vsync_pos != 0 && horiz_during_vsync_neg != 0) begin
			if(horiz_during_vsync_pos > horiz_during_vsync_neg) begin
				horiz_during_vsync <= horiz_during_vsync_pos;
			end else begin
				horiz_during_vsync <= horiz_during_vsync_neg;
			end
		end else begin
				horiz_during_vsync <= 'h00;
		end
		if(vsync_in) begin
			horiz_during_vsync_pos <= 'h01;
		end else begin
			horiz_during_vsync_neg <= 'h01;
		end
	end else begin
		if(vsync_in == 1'b0) begin
			horiz_during_vsync_neg <= horiz_during_vsync_neg + 1'b1;
		end else begin
			horiz_during_vsync_pos <= horiz_during_vsync_pos + 1'b1;
		end
	end
	last_vsync_state <= vsync_in;
end

endmodule