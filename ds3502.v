`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:19:39 06/21/2020 
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
    input [7:0] reg_addr,
    input [7:0] reg_var,
    output reg busy,
    
    output [1:0] a,
    output reg scl,
    input sda_i,
    output reg sda_o,
    output reg sda_io_ctrl//i-1,o-0
);

    assign a = 2'b00;

    reg [7:0] reg_addr_temp;
    reg [7:0] reg_var_temp;
    reg [7:0] fsm_state_cur;
    reg [15:0] delay_count;

    reg [7:0] i2c_addr_temp;
    reg [7:0] bit_temp;

    always @ (posedge clk) begin
        if(!rst) begin
            busy <= 1'b0;
            sda_io_ctrl <= 1'b0;
            scl <= 1'b1;
            sda_o <= 1'b1;
            delay_count <= 16'd0;
            fsm_state_cur <= 8'd0;
        end
        else begin
            case(fsm_state_cur)
                0 : begin
                    if(load) begin
                        reg_addr_temp <= reg_addr;
                        reg_var_temp <= reg_var;
                        busy <= 1'b1;
                        fsm_state_cur <= 8'd1;
                    end
                end
                //START BIT
                1 : begin
                    sda_o <= 1'b0;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd2;
                end
                2 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd3;
                    end
                end
                3 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        i2c_addr_temp <= 8'h50;
                        bit_temp <= 8'd0;
                        fsm_state_cur <= 8'd4;
                    end
                end
                //I2C WRITE ADDRESS
                4 : begin
                    sda_o <= i2c_addr_temp[7];
                    bit_temp <= bit_temp + 8'd1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd5;
                end
                5 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b1;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd6;
                    end
                end
                6 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd7;
                    end
                end
                7 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        if(bit_temp == 8'd8) begin
                            sda_io_ctrl <= 1'b1;
                            fsm_state_cur <= 8'd8;
                        end
                        else begin
                            i2c_addr_temp <= {i2c_addr_temp[6:0],1'b0};
                            fsm_state_cur <= 8'd4;
                        end
                    end
                end
                //I2C ADDR ACK
                8 : begin
                    if(sda_i == 1'b0)
                        fsm_state_cur <= 8'd9;
                    else fsm_state_cur <= 8'd28;
                end
                9 : begin
                    scl <= 1'b1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd9;
                end
                10 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b0;
                        sda_io_ctrl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd11;
                    end 
                end
                11 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        bit_temp <= 8'd0;
                        fsm_state_cur <= 8'd12;
                    end 
                end
                //REG ADDR
                12 : begin
                    sda_o <= reg_addr_temp[7];
                    bit_temp <= bit_temp + 8'd1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd13;
                end
                13: begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b1;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd14;
                    end
                end
                14 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 2820) begin
                        scl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd15;
                    end
                end
                15 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        if(bit_temp == 8'd8) begin
                            sda_io_ctrl <= 1'b1;
                            fsm_state_cur <= 8'd16;
                        end
                        else begin
                            reg_addr_temp <= {reg_addr_temp[6:0],1'b0};
                            fsm_state_cur <= 8'd12;
                        end
                    end
                end
                //REG ADDR ACK
                16 : begin
                    if(sda_i == 1'b0)
                        fsm_state_cur <= 8'd17;
                    else  fsm_state_cur <= 8'd28;
                end
                17 : begin
                    scl <= 1'b1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd18;
                end
                18 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b0;
                        sda_io_ctrl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd19;
                    end 
                end
                19 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        bit_temp <= 8'd0;
                        fsm_state_cur <= 8'd20;
                    end 
                end
                //REG VALUE
                20 : begin
                    sda_o <= reg_var_temp[7];
                    bit_temp <= bit_temp + 8'd1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd21;
                end
                21: begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b1;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd22;
                    end
                end
                22 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 2820) begin
                        scl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd23;
                    end
                end
                23 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        if(bit_temp == 8'd8) begin
                            sda_io_ctrl <= 1'b1;
                            fsm_state_cur <= 8'd24;
                        end
                        else begin
                            reg_var_temp <= {reg_var_temp[6:0],1'b0};
                            fsm_state_cur <= 8'd20;
                        end
                    end
                end
                //REG VALUE ACK                
                24 : begin
                    if(sda_i == 1'b0)
                        fsm_state_cur <= 8'd25;
                    else fsm_state_cur <= 8'd28;
                end
                25 : begin
                    scl <= 1'b1;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd26;
                end
                26 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b0;
                        sda_io_ctrl <= 1'b0;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd27;
                    end 
                end
                27 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410)
                        fsm_state_cur <= 8'd28;
                end
                //stop bit
                28 : begin
                    sda_io_ctrl <= 1'b0;
                    sda_o <= 1'b0;
                    delay_count <= 16'd0;
                    fsm_state_cur <= 8'd29;
                end
                29 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        scl <= 1'b1;
                        delay_count <= 16'd0;
                        fsm_state_cur <= 8'd30;
                    end 
                end
                30 : begin
                    delay_count <= delay_count + 16'd1;
                    if(delay_count == 1410) begin
                        sda_o <= 1'b1;
                        busy <= 1'b0;
                        fsm_state_cur <= 8'd0;
                    end
                end
            endcase
        end
    end

endmodule
