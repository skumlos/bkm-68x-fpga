`timescale 10 ns/10 ns // timescale / precision

module video_format_detector_tb();

reg clk = 1'b0;
reg vsync = 1'b1;
reg hsync = 1'b1;

video_format_detector vfd(
	.clk_50mhz_in(clk),
	.vsync_in(vsync),
	.hsync_in(hsync)
);

always begin
	#1
	clk = 1'b1;
	#1
	clk = 1'b0;
end

always begin
	#5617
	hsync <= 1'b0;
	#693
	hsync <= 1'b1;
end

always begin
	#1634856
	vsync <= 1'b0;
	#31811
	vsync <= 1'b1;
end
endmodule