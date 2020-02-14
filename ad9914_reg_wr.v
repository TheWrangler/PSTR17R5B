`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:38:00 01/19/2020 
// Design Name: 
// Module Name:    ad9914_wr_test 
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
module ad9914_reg_wr
    #(
        parameter IO_UPDATE_DELAY_NUM = 2
    )
    (
		input clk,
        input rst,

        input load,
        input [7:0] reg_base_addr,
        input [31:0] reg_wvar,
        output [31:0] reg_rvar,
        input [3:0] reg_byte_num,
        output res,
        output busy,
        output finish,

        output io_update,
		
        //parallel port
        output p_pwd,//1-16bit,0-8bit
        output p_wr,
        output p_rd,
		output [7 : 0] p_addr,
		output [7 : 0] p_wdata,
        input [7 : 0] p_rdata,
        output data_tri_select

        //only for debug
        //output debug_trig
    );

    //parallel port
    wire p_load;
    wire p_wr_cmd;
    wire [7 : 0] addr;
    wire [7 : 0] wdata;
    wire [7 : 0] rdata;
    wire p_busy;
    wire p_finish;

    reg p_load_reg = 0;
    reg p_wr_cmd_reg = 0;
    reg [7 : 0] addr_reg = 0;
    reg [7 : 0] wdata_reg = 0;

    assign p_load = p_load_reg;
    assign p_wr_cmd = p_wr_cmd_reg;
    assign addr = addr_reg;
    assign wdata = wdata_reg;


    parallel_wr parallel_wr_inst
    (
        .rst(rst),
		.clk(clk),
		
		.load(p_load),
        .wr_cmd(p_wr_cmd),//0-w,1-r
		.addr(addr),
		.wdata(wdata),
        .rdata(rdata),

        .busy(p_busy),
		.finish(p_finish),

        .pwd(p_pwd),//1-16bit,0-8bit
        .wr(p_wr),
        .rd(p_rd),
        .p_addr(p_addr),
		.p_wdata(p_wdata),
        .p_rdata(p_rdata),
        .data_tri_select(data_tri_select)
    );

    //
    reg [7:0] reg_base_addr_reg = 0;
    reg [7:0] reg_wvar_reg [3:0];
    reg [7:0] reg_rvar_reg [3:0];
    reg [3:0] reg_byte_num_reg = 0;
    reg res_reg = 0;
    reg busy_reg = 0;
    reg finish_reg = 1;
    reg io_update_reg = 0;
    assign reg_rvar = {reg_rvar_reg[3],reg_rvar_reg[2],reg_rvar_reg[1],reg_rvar_reg[0]};
    assign res = res_reg;
    assign busy =busy_reg;
    assign finish = finish_reg;
    assign io_update = io_update_reg;
    
	reg [7 : 0] fsm_state_cur = 0;
	reg [15 : 0] delay_count = 0;
	reg [7 : 0] reg_index = 0;
    always @ (posedge clk) begin
		if(!rst) begin
			p_load_reg <= 0;
			p_wr_cmd_reg <= 0;
            addr_reg <= 0;
            wdata_reg <= 0;

            reg_rvar_reg[0] <= 0;
            reg_rvar_reg[1] <= 0;
            reg_rvar_reg[2] <= 0;
            reg_rvar_reg[3] <= 0;

            res_reg <= 0;
            busy_reg <= 0;
            finish_reg <= 1;

            reg_index <= 0;

			io_update_reg <= 0;
			
			fsm_state_cur <= 0;
		end
		else begin
            case(fsm_state_cur)
                0:	begin
				    fsm_state_cur <= 1;
                end
                1 : begin
                    if(load) begin
                        reg_wvar_reg[0] <= reg_wvar[7:0];
					    reg_wvar_reg[1] <= reg_wvar[15:8];
					    reg_wvar_reg[2] <= reg_wvar[23:16];
					    reg_wvar_reg[3] <= reg_wvar[31:24];

                        reg_base_addr_reg <= (reg_base_addr << 2);
                        reg_byte_num_reg <= reg_byte_num - 1;

                        busy_reg <= 1;
                        finish_reg <= 0;

                        reg_index <= 0;
                        fsm_state_cur <= 2;
                    end
                end
                //write
                2 : begin 
                    if(p_finish) begin
                        wdata_reg <= reg_wvar_reg[reg_index];
                        addr_reg <= reg_base_addr_reg + reg_index;
                        p_wr_cmd_reg <= 0;
                        p_load_reg <= 1;
                        fsm_state_cur <= 3;
                    end
                end
                3 : begin
                    if(p_busy) begin
                        p_load_reg <= 0;
                        reg_index <= reg_index + 1;
                        if(reg_index == reg_byte_num_reg)
                            fsm_state_cur <= 4;
                        else fsm_state_cur <= 2;
                    end
                end
                4 : begin
                    if(p_finish) begin
                        delay_count <= 16'd0;
                        io_update_reg <= 1;
                        fsm_state_cur <= 5;
                    end
                end
                5 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == IO_UPDATE_DELAY_NUM) begin
                        io_update_reg <= 0;
                        reg_index <= 0;
                        fsm_state_cur <= 6;
                    end
                end
                //read
                6 : begin
                    if(p_finish) begin
                        addr_reg <= reg_base_addr_reg + reg_index;
                        p_wr_cmd_reg <= 1;
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
                8 : begin
                     if(p_finish) begin
                        reg_rvar_reg[reg_index] <= rdata;
                        reg_index <= reg_index + 1;
                        if(reg_index == reg_byte_num_reg)
                            fsm_state_cur <= 9;
                        else fsm_state_cur <= 6;
                     end
                end
                9 : begin
                    busy_reg <= 0;
                    finish_reg <= 1;
                    if((reg_wvar_reg[0] == reg_rvar_reg[0])
                        && (reg_wvar_reg[1] == reg_rvar_reg[1])
                        && (reg_wvar_reg[2] == reg_rvar_reg[2])
                        && (reg_wvar_reg[3] == reg_rvar_reg[3]))
                        res_reg <= 0;
                    else res_reg <= 1;
                    reg_index <= 0;
                    fsm_state_cur <= 0;
                end   
            endcase
        end
    end

    // wire [35:0] CONTROL0;
	// wire [35:0] CONTROL1;
	// wire [99:0] TRIG0;
	// assign TRIG0[0] = debug_trig;
	// assign TRIG0[8:1] = fsm_state_cur;
	// assign TRIG0[16:9] = p_wdata;
	// assign TRIG0[24:17] = p_addr;
	// assign TRIG0[25] = p_load;
	// assign TRIG0[26] = p_wr_cmd;
	// assign TRIG0[27] = p_busy;
	// assign TRIG0[28] = p_finish;
	// assign TRIG0[36:29] = reg_index;
    // assign TRIG0[37] = io_update;
    // assign TRIG0[45:38] = p_rdata;
    // assign TRIG0[53:46] = reg_base_addr;
    // assign TRIG0[85:54] = reg_rvar;
    // assign TRIG0[86] = res;

	// myila myila_inst (
	// 	.CONTROL(CONTROL0), // INOUT BUS [35:0]
	// 	.CLK(clk/*clk_100m*/), // IN
	// 	.TRIG0(TRIG0) // IN BUS [99:0]
	// );

	// myicon myicon_inst (
    // 	.CONTROL0(CONTROL0), // INOUT BUS [35:0]
	// 	.CONTROL1(CONTROL1)
	// );

	// wire [8:0] ASYNC_OUT0;
	// assign debug_trig = ASYNC_OUT0[8];

	// myvio myvio_inst (
    // 	.CONTROL(CONTROL1), // INOUT BUS [35:0]
    // 	.ASYNC_OUT(ASYNC_OUT0) // IN BUS [7:0]
	// );

endmodule
