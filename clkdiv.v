// Basically taken from https://www.fpga4student.com/2017/08/verilog-code-for-clock-divider-on-fpga.html
// I could see no license anywhere, if anyone have problems with it, I'll change it some...

module Clock_divider(
	clock_in,
	clock_out
);

input clock_in;
output reg clock_out;

reg[27:0] counter = 28'd0;

parameter DIVISOR = 28'd10;

always @(posedge clock_in)
begin
	 counter <= counter + 28'd1;
	 if(counter >= (DIVISOR-1)) counter <= 28'd0;
	 clock_out <= (counter < (DIVISOR >> 1)) ? 1'b1 : 1'b0;
end

endmodule