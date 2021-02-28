/*
cmd_prepare (0x22):
Monitor issues:
W 22 25 a0
W 22 26 01
W 22 80 00
W 22 81 00
W 22 27 09
R 22 27 29 x 5
R 22 27 09 x 8
R 22 27 00
W 22 25 a0
W 22 26 00
W 22 27 03
R 22 27 03 x 9
R 22 27 00
R 23 00 88

then repeats

W 22 25 a0
W 22 26 01
W 22 80 00 
W 22 81 00
W 22 27 09
R 22 27 09 x 13 / 4 / 12 / 13
R 22 27 00
W 22 25 a0
W 22 26 00
W 22 27 03
R 22 27 03 x 9 / 8 / 9 / 10
R 22 27 00
R 23 00 88

(so x 4)

then

W 22 25 a0
W 22 26 01
W 22 80 00
W 22 81 02
W 22 27 09
R 22 27 09 x 13
R 22 27 00
W 22 25 a0
W 22 26 06
W 22 27 03
R 22 27 03 x 35
R 22 27 00 -> read 0x23 00 32
*/
module monitor_interface(
	input slot_x,
	input clk_rw,
	input ax_d,
	input r_wx,
	input reset_x,
	output int_x,
	output int_oe_x,
	input [7:0] data_in,
	output [7:0] data_out,
	output data_oe_x,
	input clk_20mhz
);

reg data_oe;
reg irq_oe;
reg irq;
reg selected;
reg in_irq;

reg [1:0] addr_bytes;
reg [7:0] cmd_in;
reg [7:0] addr_in;
reg [7:0] val_in;
reg [7:0] data;
reg [7:0] out_data;

localparam [3:0]
    s_undef		= 'd00,
    s_irq		= 'd01,
	 s_cmd		= 'd02,
	 s_sync		= 'd03,
	 s_blip		= 'd04;

localparam [2:0]
	cs_addr		= 'd01,
	cs_data		= 'd02;

localparam [7:0]
	cmd_irq		= 'h02,
	cmd_id		= 'h20, // 20 00 88 (68X), 20 00 82 (62HS)
	cmd_video	= 'h21,
	cmd_prepare = 'h22,
	cmd_serial	= 'h23,
	cmd_blip_1	= 'h30, // no idea what these two do, seemingly not much
	cmd_blip_2	= 'h40;
	
	
reg [3:0] state;
reg [3:0] c_state;
reg [7:0] reg_serial [0:6];
reg [7:0] reg_id;

reg [15:0] reg_addr;

assign int_oe_x = irq_oe;
assign int_x = irq;
assign data_out = (selected && ((c_state != cs_data)) ? 'hFF : out_data);
//assign data_oe_x = !(r_wx && ax_d && reset_x && (state != s_undef && irq_oe));
assign data_oe_x = !(data_oe && r_wx && ax_d && reset_x);

always @ (posedge clk_rw, negedge reset_x) begin
	if(!reset_x) begin
		irq_oe		<= 'b0;
		irq			<= 'b0;
		in_irq		<= 'b0;
		selected		<= 'b0;
		data			<= 'hFF;
		data_oe		<= 'b0;
		reg_id		<= 'h88;
		state			<= s_undef;
		c_state		<= cs_addr;
		reg_addr		<= 16'h00;
		reg_serial[0] 	<= 'h32;
		reg_serial[1] 	<= 'h30;
		reg_serial[2] 	<= 'h30;
		reg_serial[3] 	<= 'h30;
		reg_serial[4] 	<= 'h35;
		reg_serial[5] 	<= 'h35;
		reg_serial[6] 	<= 'h35;
	end else begin
		if(clk_rw) begin
			case(state)
				s_undef : begin
					case(data_in)
						cmd_irq : begin
							state <= s_irq;
							selected <= 'b1;
							data_oe <= 'b1;
						end
						'hFF : begin
							if(selected) begin
								selected <= 'b0;
								data_oe <= 'b0;
								c_state <= cs_addr;
							end else begin
								selected <= 'b1;
							end
						end
						cmd_blip_1,cmd_blip_2: begin
								if(selected) begin
									state <= s_blip;
								end
						end
						default : begin 
								if(selected) begin
									cmd_in <= data_in;
									addr_bytes <= 0;
									c_state <= cs_addr;
									reg_addr <= 16'h00;
									state <= s_cmd;
									data_oe <= 'b1;
								end
						end
					endcase
				end
				s_blip : begin
					// empty on purpose
					state = s_undef;
				end
				s_irq : begin
					case(data_in)
						'h01 : irq_oe <= 'b1;
						'h00 : irq_oe <= 'b0;
						'hFF : begin
							if(!irq_oe) begin
								selected <= 'b0;
							end
							data_oe <= 'b0;
							state <= s_undef;	
						end
					endcase
				end
				s_cmd : begin
					if(ax_d) begin
						if(!r_wx) begin
								// write byte
						end
						state <= s_undef;
					end else begin
						reg_addr <= reg_addr + (data_in << addr_bytes);
						case(cmd_in)
							cmd_id : begin
								case(data_in)
									'h00 : begin
										out_data <= reg_id;
									end
									default : begin
										out_data <= 'h00;
									end
								endcase
							end
							cmd_serial : begin
								out_data <= reg_serial[data_in];
							end
						endcase
						addr_bytes <= addr_bytes + 'b1;
						c_state <= cs_data;
					end
				end
			endcase
		end
	end
end
endmodule
