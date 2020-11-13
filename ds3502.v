`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:38:44 11/12/2020 
// Design Name: 
// Module Name:    ds3502 
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
module ds3502
(
    input clk,
    input rst,

    input load,
    input r,
    output reg busy,

    output a1,
    output a0,

    output reg scl,
    output reg sda_o,
    input sda_i,
    output reg sda_io_select//0-w,1-r
);

    localparam [31:0] SCL_PERIOD_CLOCK_NUM = 5 * 3400 / 24;// SCL = 200KHz,5us
    localparam [31:0] SCL_HALF_PERIOD_CLOCK_NUM = 5 * 3400 / 24 / 2;//2.5us
    localparam [4:0] SLAVE_DEV_ADDR = 5'b01010;//WRITE ADDR
    localparam [7:0] WR_REG_ADDR = 8'h00;

    assign a1 = 1'b0;
    assign a0 = 1'b0;

    reg [31:0] delay_num = 32'd0;
    reg [7:0] state_cur = 8'd0;
    reg [7:0] reg_var;
    reg [7:0] reg_temp;
    reg [7:0] bit_count;
    reg [7:0] slave_dev_w_addr;
 
    always @ (posedge clk) begin
        if(!rst) begin
            delay_num <= 32'd0;
            scl <= 1'b1;
            sda_o <= 1'b1;
            sda_io_select <= 1'b1;
            busy <= 1'b1;
            state_cur <= 8'd0;
        end
        else case(state_cur)
            0 : begin//START
                if(load) begin
                    reg_var <= r;
                    sda_o <= 1'b0;
                    sda_io_select <= 1'b0;
                    delay_num <= 32'd0;
                    slave_dev_w_addr <= {SLAVE_DEV_ADDR,a1,a0,0};
                    busy <= 1'b1;
                    state_cur <= 8'd1;
                end
                else busy <= 1'b0;
            end
            1 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    reg_temp <= slave_dev_w_addr;
                    bit_count <= 8'd0;
                    scl <= 1'b0;
                    state_cur <= 8'd2;
                end
            end
            2 : begin//SLAVE ADDR
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    sda_o <= reg_temp[7];
                    reg_temp <= {reg_temp[6:0],1'b0};
                    bit_count <= bit_count + 8'd1;
                    state_cur <= 8'd3;
                end
            end
            3 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    state_cur <= 8'd4;
                end
            end
            4 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    if(bit_count < 8'd8)
                        state_cur <= 8'd2;
                    else state_cur <= 8'd5;
                end
            end
            5 : begin//ACK
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    sda_io_select <= 1'b1;
                    state_cur <= 8'd6;
                end
            end
            6 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    if(sda_i == 0) begin
                        state_cur <= 8'd7;
                    end
                    else begin
                        state_cur <= 8'd19;
                    end
                end
            end
            7 : begin//REG ADDR
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    reg_temp <= WR_REG_ADDR;
                    sda_io_select <= 1'b0;
                    bit_count <= 8'd0;
                    state_cur <= 8'd8;
                end
            end
            8 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    sda_o <= reg_temp[7];
                    reg_temp <= {reg_temp[6:0],1'b0};
                    bit_count <= bit_count + 8'd1;
                    state_cur <= 8'd9;
                end
            end
            9 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    state_cur <= 8'd10;
                end
            end
            10 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    if(bit_count < 8'd8)
                        state_cur <= 8'd8;
                    else state_cur <= 8'd11;
                end
            end
            11 : begin//ACK
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    sda_io_select <= 1'b1;
                    state_cur <= 8'd12;
                end
             end
            12 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    if(sda_i == 0) begin
                        state_cur <= 8'd13;
                    end
                    else begin
                        state_cur <= 8'd19;
                    end
                end
            end
            13 : begin//REG VAR
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    reg_temp <= reg_var;
                    sda_io_select <= 1'b0;
                    bit_count <= 8'd0;
                    state_cur <= 8'd14;
                end
            end
            14 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    sda_o <= reg_temp[7];
                    reg_temp <= {reg_temp[6:0],1'b0};
                    bit_count <= bit_count + 8'd1;
                    state_cur <= 8'd15;
                end
            end
            15 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    state_cur <= 8'd16;
                end
            end
            16 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    if(bit_count < 8'd8)
                        state_cur <= 8'd17;
                    else state_cur <= 8'd14;
                end
            end
            17 : begin//ACK
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    sda_io_select <= 1'b1;
                    state_cur <= 8'd18;
                end
            end
            18 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    if(sda_i == 0) begin
                        state_cur <= 8'd19;
                    end
                    else begin
                        state_cur <= 8'd19;
                    end
                end
            end
            19 : begin//STOP
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b0;
                    sda_io_select <= 1'b0;
                    state_cur <= 8'd20;
                end 
            end
            20 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_HALF_PERIOD_CLOCK_NUM) begin
                    sda_o <= 1'b0;
                    state_cur <= 8'd21;
                end 
            end
            21 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    delay_num <= 32'd0;
                    scl <= 1'b1;
                    state_cur <= 8'd22;
                end 
            end
            22 : begin
                delay_num <= delay_num + 32'd1;
                if(delay_num == SCL_PERIOD_CLOCK_NUM) begin
                    sda_o <= 1'b1;
                    state_cur <= 8'd0;
                end
            end
        endcase
    end

endmodule
