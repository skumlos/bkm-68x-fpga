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
R 23 00 88 (88 = 82 on 62HS)

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
	input slot_x_int_x,
	input clk_rw,
	input ax_d,
	input r_wx,
	input reset_x,
	output int_x,
	output int_oe_x,
	input [7:0] data_in,
	output [7:0] data_out,
	output data_oe_x,
	output video_oe_x,
	output rgb_comp_x,
	output int_ext_x,
	output hd_sd_x,
	input clk_20mhz
);

reg data_oe;
reg irq_oe;
reg irq;
reg selected;
reg in_irq;
reg video_oe;

reg [7:0] slot_no;

reg [1:0] addr_bytes;
reg [7:0] cmd_in;
reg [7:0] addr_in;
reg [7:0] val_in;
reg [7:0] data;
reg [7:0] out_data;

localparam [7:0]
    s_undef		= 'd00,
	 s_init		= 'd01,
    s_irq		= 'd02,
	 s_cmd		= 'd03,
	 s_sync		= 'd04,
	 s_blip		= 'd05,
	 s_prepare	= 'd06,
	 s_video		= 'd07;

localparam [2:0]
	cs_addr		= 'd01,
	cs_data		= 'd02;

// video formats (10 31 xx)
localparam [2:0]
	vf_no_signal	= 'h00,
	vf_576i_50hz	= 'h01,
	vf_480i_60hz	= 'h02,
	vf_480p_60hz	= 'h04;

localparam [2:0]
	work_reg			= 'd01,
	work_data		= 'd02;

localparam [2:0]
	prep_reg			= 'd01,
	prep_data		= 'd02;

localparam [2:0]
	v_reg				= 'd01,
	v_data			= 'd02;

localparam [7:0]
	vreg_colorspc	= 'h00,
	vreg_video_oe	= 'h10,
	vreg_format		= 'h31;
	
localparam [7:0]
	video_out_dis	= 'h01,
	video_oe_ext	= 'h08,
	video_oe_int	= 'h09,
	video_rgb		= 'h00,
	video_ypbpr		= 'h04;

localparam [7:0]
	cmd_irq		= 'h02,
	cmd_init		= 'h10,
	cmd_id		= 'h20, // 20 00 88 (68X), 20 00 82 (62HS)
	cmd_video	= 'h21,
	cmd_prepare = 'h22,
	cmd_serial	= 'h23,
	cmd_blip_1	= 'h30, // no idea what these two do, seemingly not much
	cmd_blip_2	= 'h40;

reg [7:0] init_reg_40;
reg [7:0] init_reg_41;
reg [7:0] init_reg_42;
reg [7:0] init_reg_43;

reg [7:0] prep_reg_20;
reg [7:0] prep_reg_21;
reg [7:0] prep_reg_22;
reg [7:0] prep_reg_24;
reg [7:0] prep_reg_27;

reg [3:0] state;
reg [3:0] c_state;
reg [3:0] v_state;
reg [3:0] i_state;

reg [7:0] reg_init;
reg [7:0] reg_video;
reg [7:0] reg_id;

reg [3:0] p_state;
reg [7:0] reg_prepare;
reg [7:0] prep_reg_27_09_reads [0:7];
reg [7:0] prep_reg_27_03_reads [0:7];
reg [7:0] prep_reg_27_read_cnt;
reg [3:0] prepare_cnt;

reg [7:0] reg_serial [0:6];

reg [15:0] reg_addr;

reg [7:0] reg_video_format;

reg video_rgb_ypbpr_x;
reg video_int_ext_x;

assign int_oe_x = irq_oe;
assign int_x = irq;
//assign data_out = (selected && ((c_state != cs_data)) ? 'hFF : out_data);
assign data_out = out_data;
//assign data_oe_x = !(r_wx && ax_d && reset_x && (state != s_undef && irq_oe));
assign data_oe_x = !(data_oe && r_wx && ax_d && reset_x);
assign video_oe_x = video_oe;
assign rgb_comp_x = video_rgb_ypbpr_x;
assign int_ext_x = video_int_ext_x;
assign hd_sd_x = (reg_video_format == 'h00) ? 'b1 : (reg_video_format < 'h04 ? 'b0 : 'b1);

reg in_reset;

always @ (clk_rw, reset_x) begin
	if(!reset_x) begin
		in_reset		<=	'b1;
		irq_oe		<= 'b0;
		irq			<= 'b0;
		in_irq		<= 'b0;
		selected		<= 'b0;
		data			<= 'hFF;
		data_oe		<= 'b0;
		reg_id		<= 'h88;
		out_data		<= 'hFF;
		state			<= s_undef;
		c_state		<= cs_addr;
		v_state		<= v_reg;
		reg_addr		<= 16'h00;
		video_oe		<= 'b1;

		init_reg_40	<= 'hFF;
		init_reg_41	<= 'hFD;
		init_reg_42	<= 'hFF;
		init_reg_43	<= 'hFD;

		reg_video_format <= vf_no_signal;
		video_rgb_ypbpr_x <= 'b0;
		video_int_ext_x <= 'b0;

		slot_no		<= 'h00;
		reg_init		<= 'h00;

		reg_serial[0] 	<= 'h32;
		reg_serial[1] 	<= 'h30;
		reg_serial[2] 	<= 'h30;
		reg_serial[3] 	<= 'h30;
		reg_serial[4] 	<= 'h35;
		reg_serial[5] 	<= 'h35;
		reg_serial[6] 	<= 'h35;

		prepare_cnt		<= 'd0;
		p_state			<= prep_reg;

		prep_reg_27_09_reads[0] <= 'd13;
		prep_reg_27_09_reads[1] <= 'd14;
		prep_reg_27_09_reads[2] <= 'd05;
		prep_reg_27_09_reads[3] <= 'd13;
		prep_reg_27_09_reads[4] <= 'd13;
		prep_reg_27_09_reads[5] <= 'd14;
		prep_reg_27_09_reads[6] <= 'd14;
		prep_reg_27_09_reads[7] <= 'd14;

		prep_reg_27_03_reads[0] <= 'd10;
		prep_reg_27_03_reads[1] <= 'd10;
		prep_reg_27_03_reads[2] <= 'd9;
		prep_reg_27_03_reads[3] <= 'd10;
		prep_reg_27_03_reads[4] <= 'd10;
		prep_reg_27_03_reads[5] <= 'd4;
		prep_reg_27_03_reads[6] <= 'd35;
		prep_reg_27_03_reads[7] <= 'd36;

		prep_reg_27_read_cnt <= 'd0;
		prep_reg_27 <= 'h00;

	end else begin
		if(in_reset) begin
			in_reset <= 'b0;
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
									out_data <= 'hFF;
								end
							end

							cmd_blip_1,cmd_blip_2: begin
								if(selected) begin
									state <= s_blip;
								end
							end

							cmd_init : begin
								if(!slot_x_int_x) begin
									cmd_in <= data_in;
									reg_init <= 'h00;
									i_state <= work_reg;
									data_oe <= 'b1;
									state <= s_init;
								end
							end

							cmd_video : begin
								if(selected) begin
									cmd_in <= data_in;
									state <= s_video;
									v_state <= v_reg;
									data_oe <= 'b1;
								end
							end

							cmd_id : begin 
								if(selected) begin
									cmd_in <= data_in;
									addr_bytes <= 0;
									c_state <= cs_addr;
									reg_addr <= 16'h00;
									state <= s_cmd;
									data_oe <= 'b1;
								end
							end

							cmd_prepare : begin
								if(selected) begin
									cmd_in <= data_in;
									state <= s_prepare;
									p_state <= prep_reg;
									data_oe <= 'b1;
								end
							end

							'h11, 
							'h50, 'h51, 'h52, 'h53, 
							'h60, 'h61, 'h62, 'h63 : begin
								if(selected) begin
									cmd_in <= data_in;
									addr_bytes <= 0;
									c_state <= cs_addr;
									reg_addr <= 16'h00;
									state <= s_cmd;
								end
							end
			/*
							default : begin 
								if(selected && slot_no != 'h00) begin
									cmd_in <= data_in;
									addr_bytes <= 0;
									c_state <= cs_addr;
									reg_addr <= 16'h00;
									state <= s_cmd;
									data_oe <= 'b1;
								end
							end*/
						endcase
						out_data <= 'hFF;
					end

					s_init : begin
						case(i_state)
							work_reg : begin
								reg_init <= data_in;
								i_state <= work_data;
								case(data_in)
									'h40 : out_data <= init_reg_40;
									'h41 : out_data <= init_reg_41;
									'h42 : out_data <= init_reg_42;
									'h43 : out_data <= init_reg_43;
									default : out_data <= data_in;
								endcase
							end
							work_data : begin
								if(!slot_x_int_x && !r_wx) begin
									case(reg_init)
										'h03 : begin
											slot_no <= data_in;
										end
										'h40 : init_reg_40 <= data_in;
										'h41 : begin
												if(data_in == 'h02) begin
													irq <= 'b1;
													init_reg_41 <= 'hFF;
												end else begin
													init_reg_41 <= data_in;
												end
										end
										'h42 : init_reg_42 <= data_in;
										'h43 : init_reg_43 <= data_in;
									endcase
									out_data <= 'hFF;
								end
								state <= s_undef;
							end
						endcase
					end

					s_blip : begin
						// empty on purpose
						state = s_undef;
					end

					s_video : begin
						case(v_state)
							v_reg : begin
								reg_video <= data_in;
								v_state <= v_data;
								out_data <= data_in;
							end
							v_data : begin
								if(!r_wx) begin 
									case(reg_video)
										vreg_colorspc : begin
											case(data_in)
												video_rgb : video_rgb_ypbpr_x <= 'b1;
												video_ypbpr : video_rgb_ypbpr_x <= 'b0;
											endcase
										end
										vreg_video_oe : begin
											case(data_in)
												video_out_dis : video_oe <= 'b1;
												video_oe_ext : begin
													video_oe <= 'b0;
													video_int_ext_x <= 'b0;
												end
												video_oe_int : begin
													video_oe <= 'b0;
													video_int_ext_x <= 'b1;
												end
											endcase
										end
									endcase
									out_data <= data_in;
								end
								state <= s_undef;
							end
						endcase
					end

					s_prepare : begin
						case(p_state)
							prep_data : begin
								if(!r_wx) begin // write
									case(reg_prepare)
										'h20 : begin
											prep_reg_20 <= data_in;
										end
										'h21 : begin
											prep_reg_21 <= data_in;
										end
										'h22 : begin
											prep_reg_22 <= data_in;
										end
										'h24 : begin
											prep_reg_24 <= data_in;
										end
										'h25 : begin
										end
										'h26 : begin
											case(data_in)
												'h01 : begin
													prepare_cnt <= prepare_cnt + 'b1;									
												end
											endcase
										end
										'h27 : begin
											prep_reg_27 <= data_in;
											case(data_in)
												'h03 : begin
													prep_reg_27_read_cnt <= prep_reg_27_03_reads[prepare_cnt-1];
												end
												'h09 : begin
													prep_reg_27_read_cnt <= prep_reg_27_09_reads[prepare_cnt-1];
												end
											endcase
										end
										'h80 : begin
										end
									endcase
									out_data <= data_in;
								end
								state <= s_undef;
							end
							prep_reg : begin
								reg_prepare <= data_in;
								out_data <= data_in;
								p_state = prep_data;
							end
						endcase
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
						out_data <= 'hFF;
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
							endcase
							addr_bytes <= addr_bytes + 'b1;
							c_state <= cs_data;
						end
					end

				endcase
			end else begin // clk_rw is low
				case(state)
					s_prepare : begin
						if(ax_d && r_wx) begin  // read data
							case(reg_prepare)
								'h20 : begin
									out_data <= prep_reg_20;
								end
								'h21 : begin
									out_data <= prep_reg_21;
								end
								'h22 : begin
									out_data <= prep_reg_22;
								end
								'h24 : begin
									out_data <= prep_reg_24;
								end
								'h27 : begin
									if(prep_reg_27_read_cnt > 'h01) begin
										prep_reg_27_read_cnt <= prep_reg_27_read_cnt - 'b1;
										out_data <= prep_reg_27;
									end else begin
										prep_reg_27 <= 'h00;
										out_data <= 'h00;
									end
								end
							endcase
						end
					end
					
					s_init : begin
						case(work_reg)
							'h40 : out_data <= init_reg_40;
							'h41 : out_data <= init_reg_41;
							'h42 : out_data <= init_reg_42;
							'h43 : out_data <= init_reg_43;
						endcase
					end
					s_cmd : begin
						if(ax_d && r_wx) begin
							case(cmd_in)
								cmd_serial : begin
									if(prepare_cnt < 'd07) begin
										out_data <= reg_id;
									end else begin
										out_data <= reg_serial[reg_addr & 'hFF];
									end
								end
								cmd_video : begin
									if(reg_video == 'h31) begin
										out_data <= reg_video_format;
									end
								end
							endcase
						end
					end
				endcase
			end
		end
	end
end
endmodule
