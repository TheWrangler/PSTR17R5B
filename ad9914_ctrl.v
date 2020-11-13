`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:37:12 01/18/2020 
// Design Name: 
// Module Name:    ad9914 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
//WARNNING:When use ad9914 sync_clk as clock source,do not reset AD9914 by set MASTER_RESET HIGH!!!

module ad9914_ctrl
#(
	parameter [7 : 0] MASTER_RESET_DELAY_NUM = 10,
	parameter [7:0] IO_UPDATE_DELAY_NUM = 2
)
(
	input clk,
	input rst,

	//input update,
	input set,
	input sweep,
	input sweep_edge,//1-positive sweep,0-negitive sweep
	input [31 : 0] lower_limit,
	input [31 : 0] upper_limit,
	input [31 : 0] positive_step,
	input [31 : 0] negitive_step, 
	input [15 : 0] positive_rate,
	input [15 : 0] negitive_rate,
	input [7:0] att,

	output busy,
	output finish,

	input dover,
	output dhold,
	output io_update,
	output master_reset,
	output dctrl,
	output [2 : 0] profile_select,
	output [3 : 0] function_select,

	output p_pwd,
	output p_rd,
	output p_wr,
	output [7 : 0] p_addr,
	input [15 : 0] p_data_in,
	output [15 : 0] p_data_out,
	output p_data_tri_select
);

	//ad9914_reg_wr
	wire p_load;
	wire [7:0] reg_base_addr;
	wire [31:0] reg_wvar;
	wire [31:0] reg_rvar;
	wire [3:0] reg_byte_num;
	wire p_res;
	wire p_busy;
	wire p_finish;

	reg p_load_reg;
	reg [7:0] reg_base_addr_reg;
	reg [31:0] reg_wvar_reg;
	reg [3:0] reg_byte_num_reg;

	assign p_load = p_load_reg;
	assign reg_base_addr = reg_base_addr_reg;
	assign reg_wvar = reg_wvar_reg;
	assign reg_byte_num = reg_byte_num_reg;
	ad9914_reg_wr ad9914_reg_wr_inst
    (
		.clk(clk),
        .rst(rst),

        .load(p_load),
        .reg_base_addr(reg_base_addr),
        .reg_wvar(reg_wvar),
        .reg_rvar(reg_rvar),
        .reg_byte_num(reg_byte_num),
        .res(p_res),
        .busy(p_busy),
        .finish(p_finish),

		.read_back_disable(1'b1),
        //.io_update(io_update),
		
        //parallel port
        .p_pwd(p_pwd),//1-16bit,0-8bit
        .p_wr(p_wr),
        .p_rd(p_rd),
		.p_addr(p_addr),
		.p_wdata(p_data_out),
        .p_rdata(p_data_in),
        .data_tri_select(p_data_tri_select)
    );

	assign function_select = 4'b0000;
	assign profile_select = 3'b000;
	assign dhold = 0;
	
	reg dctrl_reg = 0;
	assign dctrl = dctrl_reg;

	reg master_reset_reg = 0;
	assign master_reset = master_reset_reg;

	reg io_update_reg = 0;
	assign io_update = io_update_reg;
	
	reg busy_reg = 0;
	reg finish_reg = 1;
	assign busy = busy_reg;
	assign finish = finish_reg;

	reg [11:0] att_factor_reg [63:0]/*  = {12'd4096, 12'd3650,12'd3253,12'd2899,12'd2584,12'd2303,12'd2052,12'd1829,
										12'd1630,12'd1453,12'd1295,12'd1154,12'd1028,12'd916,12'd817,12'd728,
										12'd649,12'd578,12'd515,12'd459,12'd409,12'd365,12'd325,12'd289,
										12'd258,12'd230,12'd205,12'd182,12'd163,12'd145,12'd129,12'd115,
										12'd102,12'd91,12'd81,12'd72,12'd64,12'd57,12'd51,12'd45,
										12'd40,12'd36,12'd32,12'd28,12'd25,12'd23,12'd20,12'd18,
										12'd16,12'd14,12'd12,12'd11,12'd10,12'd9,12'd8,12'd7,
										12'd6,12'd5,12'd5,12'd4,12'd4,12'd3,12'd3,12'd2} */; 

	//reg [31 : 0] sfr [3 : 0] = {32'h00_05_31_20,32'h00_00_19_1c,32'h00_04_29_00,32'h00_01_03_00};
	reg [31:0] sfr0 = 32'h00_01_03_00;
	reg [31:0] sfr1 = 32'h00_04_29_00;
	reg [31:0] sfr2 = 32'h00_00_19_1c;
	reg [31:0] sfr3 = 32'h00_05_31_20;

	reg [31 : 0] lower_limit_reg = 32'd1105322465;//1000MHz+/-125MHz,step=10KHz
	reg [31 : 0] upper_limit_reg = 32'd1421128884;
	reg [31 : 0] positive_step_reg = 32'd12632;
	reg [31 : 0] negitive_step_reg = 32'd12632; 
	reg [31 : 0] rate_reg = 32'h0001_0001;//count with sysclk/24
	reg [15:0] att_reg = 16'h0000;
	reg sweep_edge_reg = 1'b1;

	reg [7:0] delay_count = 8'd0;
	reg [7 : 0] fsm_state_cur = 0;
	
	always @ (posedge clk) begin
		if(!rst) begin
			busy_reg <= 0;
			finish_reg <= 1;

			att_factor_reg[0] <= 12'd4095;
			att_factor_reg[1] <= 12'd3650;
			att_factor_reg[2] <= 12'd3253;
			att_factor_reg[3] <= 12'd2899;
			att_factor_reg[4] <= 12'd2584;
			att_factor_reg[5] <= 12'd2303;
			att_factor_reg[6] <= 12'd2052;
			att_factor_reg[7] <= 12'd1829;
			att_factor_reg[8] <= 12'd1630;
			att_factor_reg[9] <= 12'd1453;
			att_factor_reg[10] <= 12'd1295;
			att_factor_reg[11] <= 12'd1154;
			att_factor_reg[12] <= 12'd1028;
			att_factor_reg[13] <= 12'd916;
			att_factor_reg[14] <= 12'd817;
			att_factor_reg[15] <= 12'd728;
			att_factor_reg[16] <= 12'd649;
			att_factor_reg[17] <= 12'd578;
			att_factor_reg[18] <= 12'd515;
			att_factor_reg[19] <= 12'd459;
			att_factor_reg[20] <= 12'd409;
			att_factor_reg[21] <= 12'd365;
			att_factor_reg[22] <= 12'd325;
			att_factor_reg[23] <= 12'd289;
			att_factor_reg[24] <= 12'd258;
			att_factor_reg[25] <= 12'd230;
			att_factor_reg[26] <= 12'd205;
			att_factor_reg[27] <= 12'd182;
			att_factor_reg[28] <= 12'd163;
			att_factor_reg[29] <= 12'd145;
			att_factor_reg[30] <= 12'd129;
			att_factor_reg[31] <= 12'd115;
			att_factor_reg[32] <= 12'd102;
			att_factor_reg[33] <= 12'd91;
			att_factor_reg[34] <= 12'd81;
			att_factor_reg[35] <= 12'd72;
			att_factor_reg[36] <= 12'd64;
			att_factor_reg[37] <= 12'd57;
			att_factor_reg[38] <= 12'd51;
			att_factor_reg[39] <= 12'd45;
			att_factor_reg[40] <= 12'd40;
			att_factor_reg[41] <= 12'd36;
			att_factor_reg[42] <= 12'd32;
			att_factor_reg[43] <= 12'd28;
			att_factor_reg[44] <= 12'd25;
			att_factor_reg[45] <= 12'd23;
			att_factor_reg[46] <= 12'd20;
			att_factor_reg[47] <= 12'd18;
			att_factor_reg[48] <= 12'd16;
			att_factor_reg[49] <= 12'd14;
			att_factor_reg[50] <= 12'd12;
			att_factor_reg[51] <= 12'd11;
			att_factor_reg[52] <= 12'd10;
			att_factor_reg[53] <= 12'd9;
			att_factor_reg[54] <= 12'd8;
			att_factor_reg[55] <= 12'd7;
			att_factor_reg[56] <= 12'd6;
			att_factor_reg[57] <= 12'd5;
			att_factor_reg[58] <= 12'd5;
			att_factor_reg[59] <= 12'd4;
			att_factor_reg[60] <= 12'd4;
			att_factor_reg[61] <= 12'd3;
			att_factor_reg[62] <= 12'd3;
			att_factor_reg[63] <= 12'd2;

			p_load_reg <= 0;
			reg_base_addr_reg <= 0;
			reg_wvar_reg <= 0;
			reg_byte_num_reg <= 0;	

			dctrl_reg <= 0;
			io_update_reg <= 0;

			fsm_state_cur <= 0;
		end
		else case(fsm_state_cur)
			//lock parameter and reset
			0 : begin
				dctrl_reg <= 0;
				io_update_reg <= 0;
				fsm_state_cur <= 1;
			end
			1 : begin
				if(set) begin
					rate_reg <= {negitive_rate,positive_rate};
					att_reg <= att_factor_reg[att];
					busy_reg <= 1;
					finish_reg <= 0;
					fsm_state_cur <= 2;
				end
				else if(sweep) begin
					lower_limit_reg <= lower_limit;
					upper_limit_reg <= upper_limit;
					positive_step_reg <= positive_step;
					negitive_step_reg <= negitive_step;
					sweep_edge_reg <= sweep_edge;
					busy_reg <= 1;
					finish_reg <= 0;
					fsm_state_cur <= 17;
				end
			end

			//write sfr1
			2 : begin 
				if(p_finish) begin
					reg_wvar_reg <= sfr1 | 32'h00_08_00_00;
					reg_base_addr_reg <= 8'h01;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 3;
				end	
			end
			3 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 4;	
				end
			end

			//write sfr0
			4 : begin 
				if(p_finish) begin
					reg_wvar_reg <= sfr0 | 32'h00_00_40_00;
					reg_base_addr_reg <= 8'h00;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 5;
				end	
			end
			5 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 6;	
				end
			end

			//write sfr2
			6 : begin 
				if(p_finish) begin
					reg_wvar_reg <= sfr2;
					reg_base_addr_reg <= 8'h02;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 7;
				end	
			end
			7 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 8;	
				end
			end

			//write sfr3
			8 : begin 
				if(p_finish) begin
					reg_wvar_reg <= sfr3;
					reg_base_addr_reg <= 8'h03;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 9;
				end	
			end
			9 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 10;	
				end
			end

			//sweep rate
			10 : begin 
				if(p_finish) begin
					reg_wvar_reg <= rate_reg;
					reg_base_addr_reg <= 8'h08;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 11;
				end
			end
			11 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 12;
				end
			end
			
			//ps:Amplitude Scale Factor 0
			12 : begin 
				if(p_finish) begin
					reg_wvar_reg <= {att_reg,16'h0000};
					reg_base_addr_reg <= 8'h0c;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 13;
				end
			end
			13 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 14;
				end
			end
			14 : begin
				if(p_finish && (!p_res)) begin
					busy_reg <= 0;
					finish_reg <= 1;
					fsm_state_cur <= 0;
				end
			end
			
			//disable sweep
			// 15 : begin 
			// 	if(p_finish) begin
			// 		reg_wvar_reg <= sfr1;
			// 		reg_base_addr_reg <= 8'h01;
			// 		reg_byte_num_reg <= 2;
			// 		p_load_reg <= 1;
			// 		fsm_state_cur <= 16;
			// 	end	
			// end
			// 16 : begin
			// 	if(p_busy) begin
			// 		p_load_reg <= 0;
			// 		fsm_state_cur <= 17;	
			// 	end
			// end

			//lower_limit
			17 : begin 
				if(p_finish) begin
					reg_wvar_reg <= lower_limit_reg;
					reg_base_addr_reg <= 8'h04;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 18;
				end
			end
			18 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 19;
				end
			end
			
			//upper_limit
			19 : begin 
				if(p_finish) begin
					reg_wvar_reg <= upper_limit_reg;
					reg_base_addr_reg <= 8'h05;
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 20;
				end
			end
			20 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 21;
				end
			end

			//sweep step
			21 : begin 
				if(p_finish) begin
					reg_wvar_reg <= (sweep_edge_reg ? positive_step_reg : negitive_step_reg);
					reg_base_addr_reg <= (sweep_edge_reg ? 8'h06 : 8'h07);
					reg_byte_num_reg <= 2;
					p_load_reg <= 1;
					fsm_state_cur <= 22;
				end
			end
			22 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 25;
				end
			end

			//enable sweep
			// 23 : begin
			// 	if(p_finish) begin
			// 		dctrl_reg <= (sweep_edge_reg ? 1 : 0);
			// 		reg_wvar_reg <= sfr1 | 32'h00_08_00_00;
			// 		reg_base_addr_reg <= 8'h01;
			// 		reg_byte_num_reg <= 2;
			// 		p_load_reg <= 1;
			// 		fsm_state_cur <= 24;
			// 	end
			// end
			// 24 : begin
			// 	if(p_busy) begin
			// 		p_load_reg <= 0;
			// 		fsm_state_cur <= 25;
			// 	end
			// end

			//io_update
			25 : begin
				if(p_finish && (!p_res)) begin
					dctrl_reg <= (sweep_edge_reg ? 1 : 0);
					io_update_reg <= 1'b1;
					delay_count <= 8'd0;
					// busy_reg <= 0;
					// finish_reg <= 1;
					fsm_state_cur <= 26;
				end
			end

			26 : begin
				delay_count <= delay_count + 8'd1;
				if(delay_count == IO_UPDATE_DELAY_NUM) begin
					io_update_reg <= 0;
					busy_reg <= 0;
					finish_reg <= 1;
					fsm_state_cur <= 0;
				end
			end
		endcase
	end

	// wire [35:0] CONTROL0;
	// wire [99:0] TRIG0;
	// assign TRIG0[0] = update;
	// assign TRIG0[8:1] = fsm_state_cur;
	// assign TRIG0[9] = resweep_reg;
	// assign TRIG0[10] = osk;
	// assign TRIG0[11] = trig;
	// assign TRIG0[12] = dctrl;
	// assign TRIG0[13] = dover;
	// assign TRIG0[14] = resweep_osk_trig;
	// assign TRIG0[25] = p_load;
	// assign TRIG0[26] = p_wr;
	// assign TRIG0[27] = p_rd;
	// assign TRIG0[28] = p_finish;
	// assign TRIG0[36:29] = reg_index;
    // assign TRIG0[37] = io_update;
    // assign TRIG0[45:38] = p_data_in;
    // assign TRIG0[53:46] = reg_base_addr;
    // assign TRIG0[85:54] = reg_rvar;
    // assign TRIG0[86] = p_res;
	

	// myila myila_inst (
	// 	.CONTROL(CONTROL0), // INOUT BUS [35:0]
	// 	.CLK(clk), // IN
	// 	.TRIG0(TRIG0) // IN BUS [99:0]
	// );

	// myicon myicon_inst (
    // 	.CONTROL0(CONTROL0) // INOUT BUS [35:0]
	// );

endmodule