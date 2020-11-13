`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:36:38 11/10/2020 
// Design Name: 
// Module Name:    cmd_update 
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
module cmd_update
(
    input clk,
    input rst,
    input update_cmd,

    input [1:0] tr_edge,
    input [1:0] prf_edge,
    input ct,
    
    input [31:0] depack_ftw_lower_1,
    input [31:0] depack_ftw_upper_1,
    input [31:0] depack_ftw_lower_2,
    input [31:0] depack_ftw_upper_2,
    input [31:0] depack_sweep_step,
    input [15:0] depack_sweep_rate,

    input [2:0] depack_mode,
    input depack_rf_switch,
    input [5:0] depack_tx_att,
    input [7:0] depack_rx_ch1_att,
    input [7:0] depack_rx_ch2_att,
    input [7:0] depack_rx_ch3_att,
    input [7:0] depack_rx_ch1_pha,
    input [7:0] depack_rx_ch2_pha,
    input [7:0] depack_rx_ch3_pha,


    //ad9914参数加载和扫频
    output reg ad9914_load,
    output reg ad9914_sweep,

    //控制发射开关和供电开关
    output reg rf_switch,
    output rf_power,
    
    //空馈/校准控制，0-校准，1-空馈
    output reg ct_switch,

    //tv/th切换，1-tv,0-th
    output reg tvh,

    //接收通道供电控制
    output [2:0] rx_ch_pwr_ctrl,
    output reg [2:0] rx_ch_ctrl,

    //发射衰减
    output reg [5:0] tx_att,

    //接收通道增益
    output reg [5:0] rx_ch1_att,
    output reg [5:0] rx_ch2_att,
    output reg [5:0] rx_ch3_att,
    output reg rx_att_load,

    //接收通道移相
    output reg [5:0] rx_ch1_pha,
    output reg [5:0] rx_ch2_pha,
    output reg [5:0] rx_ch3_pha,

    output reg [31:0] ftw_lower_1,
    output reg [31:0] ftw_upper_1,
    output reg [31:0] ftw_lower_2,
    output reg [31:0] ftw_upper_2,
    output reg [31:0] sweep_step,
    output reg [15:0] sweep_rate
);

    reg [2:0] mode;

    always @ (posedge clk) begin
        if(!rst) begin
            ad9914_load <= 1'b0;
            rx_att_load <= 1'b0;
        end
        else if(update_cmd) begin
            mode <= depack_mode;
            rf_switch <= depack_rf_switch;
            tx_att <= depack_tx_att;
            rx_ch1_att <= depack_rx_ch1_att;
            rx_ch2_att <= depack_rx_ch2_att;
            rx_ch3_att <= depack_rx_ch3_att;
            rx_ch1_pha <= depack_rx_ch1_pha;
            rx_ch2_pha <= depack_rx_ch2_pha;
            rx_ch3_pha <= depack_rx_ch3_pha;
            ftw_lower_1 <= depack_ftw_lower_1;
            ftw_upper_1 <= depack_ftw_upper_1;
            ftw_lower_2 <= depack_ftw_lower_2;
            ftw_upper_2 <= depack_ftw_upper_2;
            sweep_step <= depack_sweep_step;
            sweep_rate <= depack_sweep_rate;
            ad9914_load <= 1'b1;
            rx_att_load <= 1'b1;
        end
        else begin
            ad9914_load <= 1'b0;
            rx_att_load <= 1'b0;
        end
    end

    always @ (mode) begin
        if(mode == 3'b000)
            rx_ch_ctrl <= 3'b001;
        else if(mode == 3'b010 || mode == 3'b011)
            rx_ch_ctrl <= 3'b011;
        else if(mode == 3'b100)
            rx_ch_ctrl <= 3'b111;
    end


    //在prf上升沿启动扫频
    always @ (posedge clk) begin
        if(!rst) begin
            ad9914_sweep <= 1'b0;
        end
        else if(prf_edge == 2'b01) begin
            ad9914_sweep <= 1'b1;
        end
        else begin
            ad9914_sweep <= 1'b0;
        end
    end

    //在prf上升沿启动发射和接收供电开关
    reg [2:0] rx_ch_pwr_ctrl_temp = 3'b000;
    reg rf_power_temp = 1'b0;
    always @ (posedge clk) begin
        if(!rst) begin
            rf_power_temp <= 1'b0;
            rx_ch_pwr_ctrl_temp <= 3'b000;
        end
        else if(prf_edge == 2'b01) begin
            rf_power_temp <= 1'b1;
            rx_ch_pwr_ctrl_temp <= 3'b111;
        end
        else if(tr_edge == 2'b10) begin
            rf_power_temp <= 1'b0;
            rx_ch_pwr_ctrl_temp <= 3'b000;
        end
    end
    assign rx_ch_pwr_ctrl = rx_ch_ctrl & rx_ch_pwr_ctrl_temp;
    assign rf_power = rf_switch & rf_power_temp;

    //在tr的下降沿切换tv/th
    always @ (posedge clk) begin
        if(!rst) begin
            tvh <= 1'b1;
        end
        else if(tr_edge == 2'b10) begin
           if(mode == 3'b010) begin
               tvh <= ~tvh;
           end
           else tvh <= 1'b1;
        end
    end

    //在prf上升沿切换空馈/校准
    always @ (posedge clk) begin
        if(!rst) begin
            ct_switch <= 1'b1;
        end
        else if(prf_edge == 2'b01) begin
            if(ct == 1)
                ct_switch <= 1'b0;
            else ct_switch <= 1'b1;
        end
    end


endmodule
