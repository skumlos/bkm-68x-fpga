module monitor_interface2(
	input slot_x_int_x,
	input clk_rw,
	input ax_d,
	input r_wx,
	input reset_x,
	output int_x,
	output int_oe_x,
	input [7:0] data_in_x,
	output [7:0] data_out,
	output data_oe_x,
	output video_oe_x,
	output rgb_comp_x,
	output int_ext_x,
	output hd_sd_x,
	input [7:0] video_format,
	input clk_50mhz_in
);

wire [7:0] data_in;
assign data_in = ~data_in_x;

reg data_oe = 'b0;
reg irq_oe = 'b0;
reg video_oe = 'b1;

reg [7:0] slot_no = 'h00;

reg [7:0] reg_in = 'h00;
reg [7:0] out_data = 'hFF;

localparam [7:0]
    s_undef		= 'd00,
	 s_init		= 'd01,
    s_irq		= 'd02,
	 s_prepare	= 'd03,
	 s_id			= 'd04,
	 s_video		= 'd05,
	 s_serial	= 'd06,
	 s_get_reg	= 'd07,
	 s_wait_next= 'd08;

// video formats (10 31 xx)
localparam [2:0]
	vf_no_signal	= 'h00,
	vf_576i_50hz	= 'h01,
	vf_480i_60hz	= 'h02,
	vf_576p_50hz	= 'h03,
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
	video_rgb		= 'h00,
	video_ypbpr		= 'h04;

localparam [7:0] val_id = 'h88;

localparam [7:0]
	cmd_irq		= 'h02,
	cmd_init		= 'h10;

reg video_rgb_ypbpr_x = 'b0;
reg video_int_ext_x = 'b0;

reg [2:0] p_state = prep_reg;
reg [7:0] reg_prepare = 'h00;

reg [7:0] cmd_id			= 'h00; // X0 00 88 (68X), X0 00 82 (62HS) (X = 2 (OPT1), 3 (OPT2) or 4 (OPT3))
reg [7:0] cmd_video		= 'h01;
reg [7:0] cmd_prepare	= 'h02;
reg [7:0] cmd_serial		= 'h03;

reg [7:0] init_reg_40	= 'hFF;
reg [7:0] init_reg_41	= 'hFD;
reg [7:0] init_reg_42	= 'hFF;
reg [7:0] init_reg_43	= 'hFD;

reg [7:0] prep_reg_20	= 'h00;
reg [7:0] prep_reg_21	= 'h00;
reg [7:0] prep_reg_22	= 'h00;
reg [7:0] prep_reg_24	= 'h00;
reg [7:0] prep_reg_27	= 'h00;

reg [7:0] prep_reg_27_09_reads [0:7];
reg [7:0] prep_reg_27_03_reads [0:7];
reg [7:0] prep_reg_27_read_cnt = 'h00;
reg [3:0] prepare_cnt = 'h00;

reg [3:0] state = s_undef;
reg [2:0] v_state = v_reg;
reg [2:0] i_state = work_reg;

reg [7:0] reg_video_format = 'h00;
reg [7:0] reg_video = 'h00;

reg [7:0] reg_serial_b0;
reg [7:0] reg_serial_b1;
reg [7:0] reg_serial_b2;
reg [7:0] reg_serial_b3;
reg [7:0] reg_serial_b4;
reg [7:0] reg_serial_b5;
reg [7:0] reg_serial_b6;

reg [3:0] serial_reads = 'h00;

assign data_out = out_data;
assign data_oe_x = !(data_oe && r_wx && ax_d && reset_x);
assign int_oe_x = !irq_oe;
assign int_x = !(init_reg_41 != 'hFF);
assign video_oe_x = !(video_oe);
assign rgb_comp_x = video_rgb_ypbpr_x;
assign int_ext_x = video_int_ext_x;
assign hd_sd_x = (reg_video_format == 'h00) ? 1'b1 : (reg_video_format < 'h03 ? 1'b0 : 1'b1);

initial begin
	reg_serial_b0 	<= 'h32;
	reg_serial_b1 	<= 'h30;
	reg_serial_b2 	<= 'h30;
	reg_serial_b3 	<= 'h30;
	reg_serial_b4 	<= 'h35;
	reg_serial_b5 	<= 'h35;
	reg_serial_b6 	<= 'h35;

	prep_reg_27_09_reads[0] <= 8'd13;
	prep_reg_27_09_reads[1] <= 8'd14;
	prep_reg_27_09_reads[2] <= 8'd05;
	prep_reg_27_09_reads[3] <= 8'd13;
	prep_reg_27_09_reads[4] <= 8'd13;
	prep_reg_27_09_reads[5] <= 8'd14;
	prep_reg_27_09_reads[6] <= 8'd14;
	prep_reg_27_09_reads[7] <= 8'd14;

	prep_reg_27_03_reads[0] <= 8'd10;
	prep_reg_27_03_reads[1] <= 8'd10;
	prep_reg_27_03_reads[2] <= 8'd9;
	prep_reg_27_03_reads[3] <= 8'd10;
	prep_reg_27_03_reads[4] <= 8'd10;
	prep_reg_27_03_reads[5] <= 8'd4;
	prep_reg_27_03_reads[6] <= 8'd35;
	prep_reg_27_03_reads[7] <= 8'd36;

	irq_oe <= 'b1;
	data_oe <= 'b0;

	reg_video_format <= 'h00;
	video_rgb_ypbpr_x <= 'b0; // init ypbpr
	video_int_ext_x <= 'b0; // init external sync
	video_oe <= 'b1;

	init_reg_40 <= 'hFF;
	init_reg_41 <= 'hFD;
	init_reg_42 <= 'hFF;
	init_reg_43 <= 'hFD;
	id_read <= 1'b0;
	serial_reads <= 'h0;
	strobe_irq_clr <= 'b0;
	irq_cleared <= 'b1;
end

always @ (slot_no) begin
	case(slot_no)
		'h02: begin
			cmd_id		<= 'h20;
			cmd_video	<= 'h21;
			cmd_prepare	<= 'h22;
			cmd_serial	<= 'h23;
		end
		'h03: begin
			cmd_id		<= 'h30;
			cmd_video	<= 'h31;
			cmd_prepare	<= 'h32;
			cmd_serial	<= 'h33;
		end
		'h04: begin
			cmd_id		<= 'h40;
			cmd_video	<= 'h41;
			cmd_prepare	<= 'h42;
			cmd_serial	<= 'h43;
		end
		default : begin // does this make sense?
			cmd_id		<= 'h00;
			cmd_video	<= 'h01;
			cmd_prepare	<= 'h02;
			cmd_serial	<= 'h03;
		end
	endcase
end

reg [7:0] clear_irq = 'h00;
reg strobe_irq_clr = 'b0;
reg irq_cleared = 'b0;
/*
always@(video_format) begin
	pending_irq <= init_reg_41 & 8'hDF;
	reg_video_format <= video_format;
	strobe_irq_req <= 'b1;
end
*/
reg [7:0] elapsed_s = 'h0;
reg [31:0] clk_count = 'h00;
localparam frq_hz = 50000000;

always @ (posedge clk_50mhz_in) begin
	clk_count <= clk_count + 1'b1;
	if(clk_count == frq_hz) begin
		clk_count <= 'h0;
		elapsed_s <= elapsed_s + 1'b1;
	end
end

reg id_read = 1'b0;

reg [3:0] init_phase = 'h00;

always @ (posedge clk_50mhz_in) begin
	case({strobe_irq_clr,irq_cleared})
		2'b10 : begin
			//init_reg_41 <= init_reg_41 | clear_irq;
			init_reg_41 <= 'hFF;
			irq_cleared <= 1'b1;
		end
		2'b01 : begin
			irq_cleared <= 1'b0;
		end
		default: irq_cleared <= irq_cleared;
	endcase

	case(init_phase)
		'h00 : begin
			if(init_reg_41 == 'hFF) begin
				init_phase <= 'h01;
			end
		end
		'h01 : begin
			if(id_read == 1'b1 && elapsed_s > 'hC) begin
				init_reg_41 <= 'hFB;
				init_phase <= 'h02;
			end
		end
		'h02 : begin
			if(init_reg_41 == 'hFF && elapsed_s > 'h13) begin
				init_reg_41 <= 'hEF;
				init_phase <= 'h03;
			end
		end
		'h03 : begin
			if(init_reg_41 == 'hFF && video_format != reg_video_format) begin
//			if(init_reg_41 == 'hFF && elapsed_s == 'h16) begin
				reg_video_format <= video_format;
//				reg_video_format <= 'h02;
				init_reg_41 <= 'hDF;
//				init_phase <= 'h04;
			end
		end
	endcase	
end
/*
always @ (posedge strobe_irq_req, posedge strobe_irq_clr) begin
	if(strobe_irq_req == 1'b1) begin
		init_reg_41 <= pending_irq;
	end else if(strobe_irq_clr == 1'b1) begin
		init_reg_41 <= clear_irq;
	end
end
*/
always @ (posedge clk_rw, negedge reset_x) begin
	if(!reset_x) begin
		state <= s_undef;
		data_oe <= 'b0;
		irq_oe <= 'b1;
		prep_reg_27_read_cnt <= 'd0;
		prep_reg_27 <= 'h00;
	end else begin
		if(irq_cleared == 1'b1) strobe_irq_clr <= 'b0;
		case(state)
			s_undef: begin
				case(data_in)

					'hFF : begin
						if(!ax_d && r_wx) begin
							state <= s_get_reg;
						end
						data_oe <= 'b0;
						out_data <= 'hFF;
					end

					cmd_irq : begin
						if(!ax_d && !r_wx) begin
							data_oe <= 'b1;
							state <= s_irq;
						end else begin
							state <= s_undef;
						end
					end

					cmd_init : begin
						if(!slot_x_int_x && !ax_d && !r_wx) begin
							reg_in <= 'h00;
							i_state <= work_reg;
							data_oe <= 'b1;
							state <= s_init;
						end else begin
							state <= s_wait_next;
						end
					end

					default : begin
						state <= s_undef;
					end
				endcase
			end

			s_wait_next : begin
				case(data_in)
					'hFF : begin
						if(!ax_d && r_wx) begin
							state <= s_undef;
							data_oe <= 'b0;
						end else begin
							state <= s_wait_next;
						end
						out_data <= 'hFF;
					end
					default : state <= s_wait_next;
				endcase
			end

			s_get_reg : begin
				case(data_in)
					cmd_id : begin
						data_oe <= 'b1;
						state <= s_id;
					end

					cmd_video : begin
						state <= s_video;
						v_state <= v_reg;
						out_data <= data_in;
						data_oe <= 'b1;
					end

					cmd_prepare : begin
						state <= s_prepare;
						out_data <= data_in;
						p_state <= prep_reg;
						data_oe <= 'b1;
					end

					cmd_serial : begin
						data_oe <= 'b1;
						out_data <= data_in;
						state <= s_serial;
					end

					default : begin
						data_oe <= 'b0;
						state <= s_wait_next;
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
											prepare_cnt <= prepare_cnt + 4'h1;
										end
										default: begin
											prepare_cnt <= 'h00;
										end
									endcase
								end
								'h27 : begin
									prep_reg_27 <= data_in;
									case(data_in)
										'h03 : begin
//											prep_reg_27_read_cnt <= prep_reg_27_03_reads[prepare_cnt-1];
											case(prepare_cnt)
												'h00 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[0];
												'h01 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[1];
												'h02 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[2];
												'h03 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[3];
												'h04 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[4];
												'h05 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[5];
												'h06 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[6];
												'h07 : prep_reg_27_read_cnt <= prep_reg_27_03_reads[7];
												default : prep_reg_27_read_cnt <= prep_reg_27_03_reads[0];
											endcase
										end
										'h09 : begin
//											prep_reg_27_read_cnt <= prep_reg_27_09_reads[prepare_cnt-1];
											case(prepare_cnt)
												'h00 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[0];
												'h01 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[1];
												'h02 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[2];
												'h03 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[3];
												'h04 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[4];
												'h05 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[5];
												'h06 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[6];
												'h07 : prep_reg_27_read_cnt <= prep_reg_27_09_reads[7];
												default : prep_reg_27_read_cnt <= prep_reg_27_09_reads[0];
											endcase
										end
									endcase
								end
								'h80 : begin
								end
								default : begin
								end
							endcase
							out_data <= data_in;
						end
						state <= s_wait_next;
					end
					prep_reg : begin
						reg_prepare <= data_in;
						out_data <= data_in;
						case(data_in)
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
									prep_reg_27_read_cnt <= prep_reg_27_read_cnt - 4'h1;
									out_data <= prep_reg_27;
								end else begin
									prep_reg_27 <= 'h00;
									out_data <= 'h00;
								end
							end
							default : out_data <= data_in;
						endcase
						p_state = prep_data;
					end
					default : begin
						out_data <= 'hFF;
					end
				endcase
			end

			s_serial : begin
				case(data_in)
					'h00 : begin
						if(serial_reads < 'h06) begin
							out_data <= val_id;
							serial_reads <= serial_reads + 1'b1;
						end else begin
							out_data <= reg_serial_b0;
						end
					end
					'h01 : out_data <= reg_serial_b1;
					'h02 : out_data <= reg_serial_b2;
					'h03 : out_data <= reg_serial_b3;
					'h04 : out_data <= reg_serial_b4;
					'h05 : out_data <= reg_serial_b5;
					'h06 : out_data <= reg_serial_b6;
					default : out_data <= reg_serial_b0;
				endcase
				state <= s_wait_next;
			end

			s_video : begin
				case(v_state)
					v_reg : begin
						reg_video <= data_in;
						v_state <= v_data;
						case(data_in)
							vreg_format : out_data <= reg_video_format;
							default : out_data <= data_in;
						endcase
					end
					v_data : begin
						if(!r_wx) begin // write data
							case(reg_video)
								vreg_colorspc : begin
									case(data_in)
										video_rgb : video_rgb_ypbpr_x <= 'b1;
										video_ypbpr : video_rgb_ypbpr_x <= 'b0;
										default: video_rgb_ypbpr_x <= 'b1;
									endcase
								end
								vreg_video_oe : begin
									video_int_ext_x <= data_in[0];
									// video_apa_on <= data_in[1]; // not implemented
									video_oe <= data_in[3];
								end
								default : begin
									out_data <= data_in;
								end
							endcase
						end
						state <= s_wait_next;
					end
				endcase
			end

			s_id : begin
				out_data <= val_id;
				state <= s_wait_next;
				id_read <= 1'b1;
			end

			s_init : begin
				case(i_state)
					work_reg : begin
						reg_in <= data_in;
						i_state <= work_data;
						case(data_in)
							'h40 : out_data <= init_reg_40;
							'h41 : out_data <= init_reg_41;
							'h42 : out_data <= init_reg_42;
							'h43 : out_data <= init_reg_43;
							default : out_data <= 'hFF;
						endcase
					end
					work_data : begin
						if(!slot_x_int_x && !r_wx) begin
							case(reg_in)
								'h03 : begin
									slot_no <= data_in;
								end
								'h40 : init_reg_40 <= data_in;
								'h41 : begin
									clear_irq <= data_in;
									strobe_irq_clr <= 'b1;									
								end
								'h42 : init_reg_42 <= data_in;
								'h43 : init_reg_43 <= data_in;
								default : out_data <= 'hFF;
							endcase
							out_data <= 'hFF;
						end
						state <= s_wait_next;
					end
				endcase
			end

			s_irq: begin
				case(data_in)
					'h01 : begin
						irq_oe <= 'b0;
						state <= s_irq;
					end
					'h00 : begin
						irq_oe <= 'b1;
						state <= s_irq;
					end
					'hFF : begin
						data_oe <= 'b0;
						state <= s_undef;
					end
					default : begin
						irq_oe <= 'b1;
						state <= s_undef;
					end
				endcase
			end

			default : state <= s_undef;
		endcase
	end
end
endmodule
