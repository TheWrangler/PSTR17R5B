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
	parameter [7 : 0] MASTER_RESET_DELAY_NUM = 10
)
(
	input clk,
	input rst,

	input update,
	input [31 : 0] lower_limit,
	input [31 : 0] upper_limit,
	input [31 : 0] positive_step,
	input [15 : 0] positive_rate,
	input [31 : 0] resweep_period,

	output busy,
	output finish,

	output trig,
	output pre_trig,
	output resweep,

	output osk,
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
	input [7 : 0] p_data_in,
	output [7 : 0] p_data_out,
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

        .io_update(io_update),
		
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

	reg pre_trig_reg = 0;
	assign pre_trig = pre_trig_reg;

	reg master_reset_reg = 0;
	assign master_reset = master_reset_reg;

	reg resweep_state = 0;
	//reg resweep_reg = 0;
	assign resweep = resweep_state;
	
	reg busy_reg = 0;
	reg finish_reg = 1;
	assign busy = busy_reg;
	assign finish = finish_reg;

	reg [31 : 0] sfr [3 : 0] = {32'h00_05_31_20,32'h00_00_19_1c,32'h00_04_29_00,32'h00_01_03_00};//SFR4、SFR3、SFR2、SFR1
	//reg [31 : 0] sfr [3 : 0] = {32'h00_05_31_20,32'h00_00_19_1c,32'h00_01_43_00,32'h00_04_29_00};//SFR4、SFR3、SFR1、SFR2
	//reg [7 : 0] sfr_addr[3 : 0] = {8'h03,8'h02,8'h00,8'h01};

	reg [31 : 0] lower_limit_reg = 32'd1105322465;//1000MHz+/-125MHz,step=10KHz
	reg [31 : 0] upper_limit_reg = 32'd1421128884;
	reg [31 : 0] positive_step_reg = 32'd12632;
	reg [15 : 0] positive_rate_reg = 32'h0001_0001;//count with sysclk/24

	// reg [31 : 0] lower_limit_reg = 32'd1108480530;//1002.5MHz+/-125MHz,step=10KHz
	// reg [31 : 0] upper_limit_reg = 32'd1424286948;
	// reg [31 : 0] positive_step_reg = 32'd12632;
	// reg [15 : 0] positive_rate_reg = 32'h0004_0004;//count with sysclk/24

	// reg [31 : 0] lower_limit_reg = 32'h0000_0000;
	// reg [31 : 0] upper_limit_reg = 32'h0000_0000;
	// reg [31 : 0] positive_step_reg = 32'h0000_0000;//fixed freq and no re-sweep when 0
	// reg [15 : 0] positive_rate_reg = 16'h0000;
	reg [31 : 0] resweep_period_reg = 32'h0000_0000;
	
	reg [7 : 0] fsm_state_cur = 0;
	reg [31 : 0] delay_count = 0;
	reg [7 : 0] reg_index = 0;

	reg fixed_freq_enable = 0;
	reg osk_trig_enable = 0;
	
	always @ (posedge clk) begin
		if(!rst) begin
			busy_reg <= 0;
			finish_reg <= 1;
			
			p_load_reg <= 0;
			reg_base_addr_reg <= 0;
			reg_wvar_reg <= 0;
			reg_byte_num_reg <= 0;	

			reg_index <= 0;	

			//delay_count <= 0;
			//master_reset_reg <= 1;
			dctrl_reg <= 0;
			pre_trig_reg <= 0;

			fixed_freq_enable <= 0;
			osk_trig_enable <= 0;
			resweep_state <= 0;

			fsm_state_cur <= 0;
		end
		else case(fsm_state_cur)
			//lock parameter and reset
			0 : begin
				dctrl_reg <= 0;
				pre_trig_reg <= 0;
				osk_trig_enable <= 0;
				resweep_state <= 0;
				reg_index <= 0;

				fsm_state_cur <= 1;
			end
			1 : begin
				if(update) begin
					lower_limit_reg <= lower_limit;
					upper_limit_reg <= upper_limit;
					positive_step_reg <= positive_step;
					positive_rate_reg <= positive_rate;
					resweep_period_reg <= resweep_period;

					busy_reg <= 1;
					finish_reg <= 0;

					//delay_count <= 0;
					//master_reset_reg <= 1;

					fixed_freq_enable <= (positive_step == 0) ? 1 : 0;
					
					fsm_state_cur <= 3;
				end
			end
			
			// 2 : begin
			// 	delay_count <= delay_count + 16'd1;
			// 	if(delay_count == MASTER_RESET_DELAY_NUM) begin
			// 		//master_reset_reg <= 0;
			// 		reg_index <= 0;
			// 		fsm_state_cur <= 3;
			// 	end
			// end

			//write sfr
			3 : begin 
				if(p_finish) begin
					reg_wvar_reg <= sfr[reg_index];
					reg_base_addr_reg <= reg_index;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 4;
				end	
			end
			4 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					reg_index <= reg_index + 1;
					if(reg_index == 3)
						fsm_state_cur <= 5;
					else fsm_state_cur <= 3;	
				end
			end
			
			//lower_limit
			5 : begin 
				if(p_finish) begin
					reg_wvar_reg <= lower_limit_reg;
					reg_base_addr_reg <= reg_index;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 6;
				end
			end
			6 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					reg_index <= reg_index + 1;
					fsm_state_cur <= 7;
				end
			end
			
			//upper_limit
			7 : begin 
				if(p_finish) begin
					reg_wvar_reg <= upper_limit_reg;
					reg_base_addr_reg <= reg_index;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 8;
				end
			end
			8 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					reg_index <= reg_index + 1;
					fsm_state_cur <= 9;
				end
			end
			
			//positive_step
			9 : begin 
				if(p_finish) begin
					reg_wvar_reg <= positive_step_reg;
					reg_base_addr_reg <= reg_index;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 10;
				end
			end
			10 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					reg_index <= reg_index + 2;
					fsm_state_cur <= 11;
				end
			end
			
			//positive rate
			11 : begin 
				if(p_finish) begin
					reg_wvar_reg <= positive_rate_reg;
					reg_base_addr_reg <= reg_index;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 12;
				end
			end
			12 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 13;
				end
			end

			//ps:Amplitude Scale Factor 0
			13 : begin 
				if(p_finish) begin
					reg_wvar_reg <= 32'h0f_ff_00_00;
					reg_base_addr_reg <= 8'h0c;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 14;
				end
			end
			14 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 15;
				end
			end

			15 : begin
				if(p_finish && (!p_res)) begin
					osk_trig_enable <= 1;
					fsm_state_cur <= 16;
				end
			end

			//enable sweep
			16 : begin
				pre_trig_reg <= 0; 
				if(p_finish) begin
					dctrl_reg <= 1;
					reg_wvar_reg <= sfr[1] | 32'h00_08_00_00;
					reg_base_addr_reg <= 8'h01;
					reg_byte_num_reg <= 4;
					p_load_reg <= 1;
					fsm_state_cur <= 17;
				end
			end
			17 : begin
				if(p_busy) begin
					p_load_reg <= 0;
					fsm_state_cur <= 18;
				end
			end
			18 : begin
				if(p_finish) begin
					busy_reg <= 0;
					finish_reg <= 1;
					dctrl_reg <= 0;
					delay_count <= 0;
					fsm_state_cur <= 19;
				end
			end
			19 : begin
				delay_count <= delay_count + 1;
				if(update)
					fsm_state_cur <= 0;
				else if((delay_count > resweep_period_reg) && (!fixed_freq_enable)) begin
					resweep_state <= 1;
					fsm_state_cur <= 16;
				end
				else if(delay_count > resweep_period_reg - 32'd40)
					pre_trig_reg <= 1;
			end
		endcase
	end

	//resweep trig & osk
	wire resweep_osk_trig;
	assign resweep_osk_trig = resweep_state ? ~dover : 0;

	//first sweep trig & osk
	wire initsweep_osk_trig;
	reg initsweep_osk_trig_enable = 0;
	reg [7:0] initsweep_osk_trig_delay_count = 0;
	reg [3:0] initsweep_osk_trig_sta = 0;
	always @ (posedge clk) begin
		if(!rst) begin
			initsweep_osk_trig_delay_count <= 0;
			initsweep_osk_trig_enable <= 0;
			initsweep_osk_trig_sta <= 0;
		end
		case (initsweep_osk_trig_sta)
			0 : begin
				if(update) begin
					initsweep_osk_trig_enable <= 0;
					initsweep_osk_trig_delay_count <= 0;
					initsweep_osk_trig_sta <= 1;
				end
			end
			1 : begin
				initsweep_osk_trig_delay_count <= initsweep_osk_trig_delay_count + 1;
				if(initsweep_osk_trig_delay_count == 5) begin
					initsweep_osk_trig_sta <= 2;	
				end
			end
			2 : begin
				if(osk_trig_enable)
					initsweep_osk_trig_sta <= 3;
			end
			3 : begin
				if(io_update) begin
					initsweep_osk_trig_delay_count <= 0;
					initsweep_osk_trig_sta <= 4;
				end
			end
			4 : begin
				initsweep_osk_trig_delay_count <= initsweep_osk_trig_delay_count + 1;
				if(initsweep_osk_trig_delay_count == 5) begin
					initsweep_osk_trig_enable <= 1;
					initsweep_osk_trig_sta <= 0;	
				end
			end
		endcase
	end
	assign initsweep_osk_trig = initsweep_osk_trig_enable ? ~dover : 0;

	assign osk = (resweep_state ? resweep_osk_trig : initsweep_osk_trig) | fixed_freq_enable;
	assign trig = osk;

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
