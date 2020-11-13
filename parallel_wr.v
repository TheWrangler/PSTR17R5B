`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:43:55 01/19/2020 
// Design Name: 
// Module Name:    parallel_wr 
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
module parallel_wr
    #(
		parameter [15 : 0] MAIN_CLOCK_PERIOD = 8,
        parameter [15 : 0] RD_DELAY_CLOCK_PERIOD = 8/*40*/,
        parameter [15 : 0] WR_DELAY_CLOCK_PERIOD = 8/*20*/,
		parameter [3 : 0] ADDR_WIDTH = 8,
		parameter [5 : 0] DATA_WIDTH = 16
	)
    (
        input rst,
		input clk,
		
		input load,
        input wr_cmd,//0-w,1-r
		input [ADDR_WIDTH - 1 : 0] addr,
		input [DATA_WIDTH - 1 : 0] wdata,
        output [DATA_WIDTH - 1 : 0] rdata,

        output busy,
		output finish,

        output pwd,//1-16bit,0-8bit
        output wr,
        output rd,
        output [ADDR_WIDTH - 1 : 0] p_addr,
		output [DATA_WIDTH - 1 : 0] p_wdata,
        input [DATA_WIDTH - 1 : 0] p_rdata,
        output data_tri_select
    );

    localparam [15 : 0] RD_DELAY_CLOCK_NUM = RD_DELAY_CLOCK_PERIOD / MAIN_CLOCK_PERIOD;
    localparam [15 : 0] WR_DELAY_CLOCK_NUM = WR_DELAY_CLOCK_PERIOD / MAIN_CLOCK_PERIOD;

    reg busy_reg = 1'b0;
	reg finish_reg = 1'b1;
    assign busy = busy_reg;
	assign finish = finish_reg;

    assign pwd = 1;

    reg wr_reg = 1;
    reg rd_reg = 1;
    assign wr = wr_reg;
    assign rd = rd_reg;

    reg [ADDR_WIDTH - 1 : 0] p_addr_reg = 0;
    reg [DATA_WIDTH - 1 : 0] p_wdata_reg = 0;
    reg data_tri_select_reg;
    assign p_addr = p_addr_reg;
    assign p_wdata = p_wdata_reg;
    assign data_tri_select = data_tri_select_reg;

    reg [DATA_WIDTH - 1 : 0] rdata_reg = 0;
    assign rdata = rdata_reg;

    reg wr_cmd_reg;

    reg [15 : 0] delay_count = 16'd0;
    reg [7 : 0] fsm_state_cur = 0;
    always @ (posedge clk) begin
        if(!rst) begin
            busy_reg <= 1'b0;
	        finish_reg <= 1'b1;
            wr_reg <= 1;
            rd_reg <= 1;
            p_addr_reg <= 0;
            p_wdata_reg <= 0;
            rdata_reg <= 0;
            fsm_state_cur <= 0;
        end
        else begin
            case(fsm_state_cur)
                0 : begin
                    delay_count <= 16'd0;
                    fsm_state_cur <= 1;
                end
                1 : begin
                    if(load) begin
                        wr_cmd_reg <= wr_cmd;
                        p_addr_reg <= addr;
                        p_wdata_reg <= wdata;
                        busy_reg <= 1;
                        finish_reg <= 0;
                        fsm_state_cur <= 2;
                    end
                end
                2 : begin
                    delay_count <= 16'd0;
                    data_tri_select_reg <= wr_cmd_reg;
                    if(wr_cmd_reg) begin
                        rd_reg <= 0;
                        fsm_state_cur <= 3;
                    end
                    else begin
                        wr_reg <= 0;
                        fsm_state_cur <= 6;
                    end         
                end
                //read
                3 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count >= RD_DELAY_CLOCK_NUM) begin
                        rdata_reg <= p_rdata;
                        rd_reg <= 1; 
                        delay_count <= 0;
                        fsm_state_cur <= 5;
                    end
                end
                5 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count >= RD_DELAY_CLOCK_NUM) begin
                        busy_reg <= 1'b0;
                        delay_count <= 16'd0;
	                    finish_reg <= 1'b1;
                        fsm_state_cur <= 0;
                    end
                end
                //write
                6 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count >= WR_DELAY_CLOCK_NUM) begin
                        wr_reg <= 1; 
                        delay_count <= 0;
                        fsm_state_cur <= 7;
                    end
                end 
                7 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count >= WR_DELAY_CLOCK_NUM) begin
                        busy_reg <= 1'b0;
                        delay_count <= 16'd0;
	                    finish_reg <= 1'b1;
                        fsm_state_cur <= 0;
                    end
                end
            endcase
        end
    end

endmodule
