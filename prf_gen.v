`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:35:31 08/09/2020 
// Design Name: 
// Module Name:    tr_gen 
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
module prf_gen
(
    input clk,
    input rst,
    input update,
    input [31:0] pulse_clock_num,//脉冲宽度时钟周期数
    input [31:0] sweep_clock_num,//扫频周期时钟周期数
    input [31:0] ys_clock_num,   //触发延时时钟周期数
    input [31:0] ct_clock_num,   //校准时间时钟周期数

	output reg tr,
    output reg [1:0] tr_edge,
    output reg prf,
    output reg [1:0] prf_edge,
    output reg ct
);

    reg [31:0] pulse_clock_num_reg;//脉冲宽度时钟周期数
    reg [31:0] sweep_clock_num_reg;//扫频周期时钟周期数
    reg [31:0] ct_clock_num_reg;   //校准时间时钟周期数
    reg [31:0] ys_clock_num_reg;   //触发延时时钟周期数

    reg [31:0] prf_delay_count = 32'd0;
    reg [31:0] tr_delay_count = 32'd0;
    reg gen_enable = 1'b0;
    always @ (posedge clk) begin
        if(!rst) begin
            prf <= 1'b0;
            tr <= 1'b0;
            prf_delay_count <= 32'd0;
            tr_delay_count <= 32'd0;
        end
        else if(update) begin
            pulse_clock_num_reg <= pulse_clock_num;
            sweep_clock_num_reg <= sweep_clock_num;
            ys_clock_num_reg <= ys_clock_num;
            prf_delay_count <= ys_clock_num/* 32'd0 */;
            tr_delay_count <= 32'd0;
            
            gen_enable <= 1'b1;
        end
        else  if(gen_enable) begin
            prf_delay_count <= prf_delay_count + 1;
            if(prf_delay_count < sweep_clock_num_reg - pulse_clock_num_reg)
                prf <= 1'b0;
            else begin
                if(prf_delay_count < sweep_clock_num_reg)
                    prf <= 1'b1;
                else begin
                    prf <= 1'b0;
                    prf_delay_count <= 32'd0;
                end
            end

            tr_delay_count <= tr_delay_count + 1;
            if(tr_delay_count < sweep_clock_num_reg /* + ys_clock_num_reg */ - pulse_clock_num_reg)
                tr <= 1'b0;
            else begin
                if(tr_delay_count < sweep_clock_num_reg/*  + ys_clock_num_reg */)
                    tr <= 1'b1;
                else begin
                    tr <= 1'b0;
                    tr_delay_count <= 32'd0;
                end
            end 
        end
    end


    always @ (posedge clk) begin
        if(!rst) begin
            tr_edge <= 2'b00;
            prf_edge <= 2'b11;
        end
        else begin
            tr_edge <= {tr_edge[0],tr};
            prf_edge <= {prf_edge[0],prf};
        end
    end


    reg [31:0] ct_delay_count = 32'd0;
    always @ (posedge clk) begin
        if(!rst) begin
            ct <= 1'b0;
            ct_delay_count <= 32'd0;
        end
        else if(update) begin
            ct_clock_num_reg <= ct_clock_num;
            ct_delay_count <= 32'd0;
        end
        else  if(gen_enable) begin
            if(ct_delay_count < ct_clock_num_reg) begin
                ct_delay_count <= ct_delay_count + 1;
                ct <= 1'b1;
            end
            else ct <= 1'b0;
        end
    end


endmodule
