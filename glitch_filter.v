// Basically stolen from here: https://www.edaboard.com/threads/glitch-filter-vhdl-lattice-document.376753/

module glitch_filter (
	input clk,
	input in,
	output reg out
);

parameter FILTER_LEN = 5;
reg [FILTER_LEN-1:0] shift_reg;

always @(posedge clk) begin
	// shift register for input in.
	shift_reg <= {shift_reg[FILTER_LEN-2:0], in};
	// set/reset flip-flop
	if      (&shift_reg)  out <= 1'b1;  // all one's condition on shift_reg, & is reduction AND
	else if (~|shift_reg) out <= 1'b0;  // all zero's condition on shift_reg, ~| is a reduction NOR
end

endmodule

