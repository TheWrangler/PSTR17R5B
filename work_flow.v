`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:45:10 02/25/2020 
// Design Name: 
// Module Name:    work_flow 
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
module work_flow
(
    input clk,
    input rst,

    input [31:0] ct_period,
    input [1:0] tv_mode,
    input ad9914_update_2,
    input ad9914_osk_temp,
    input ad9914_trig_1,
    input ad9914_trig_2,
    input [2:0] rx_ch_pwr_ctrl,

    output ad9914_osk_2,
    output tr,
    output lo,
    output tv,
    output [2:0] rx_ch_ctrl
);

    ////////////////////////////////////////////////////////////////
    // CT work flow
    //when CT enabled, enable dds2,sweep ct_period then disable osk2
    reg ct_enable = 1'b0;
    assign ad9914_osk_2 = ct_enable ? ad9914_osk_temp : 1'b0;
    assign tr = ct_enable ? 1'b1 : 1'b0;
    assign lo = ct_enable ? 1'b1 : 1'b0;
    assign rx_ch_ctrl = ct_enable ? 3'b000 : rx_ch_pwr_ctrl;

    reg [31:0] ct_delay_count = 32'h0000_0000;
    reg [31:0] ct_period_reg;
    reg [5:0] ct_fsm_sta = 0;
    always @ (posedge clk) begin
        if(!rst) begin
            ct_enable <= 1'b0;
            ct_fsm_sta <= 0;
        end
        else begin
            case (ct_fsm_sta)
                0 : begin
                    if(ad9914_update_2) begin
                        ct_enable <= 1'b1;
                        ct_period_reg <= ct_period;
                        ct_fsm_sta <= 1;
                    end
                end
                1 : begin
                    if(ad9914_trig_2) begin
                        ct_delay_count <= 0;
                        ct_fsm_sta <= 2;
                    end
                end
                2 : begin
                    ct_delay_count <= ct_delay_count + 1'b1;
                    if(ct_delay_count == ct_period_reg) 
                        ct_fsm_sta <= 3;
                end
                3 : begin
                    ct_enable <= 1'b0;
                    ct_fsm_sta <= 1'b0;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////
    // TV/TH
    // mode=11,switch when posedge-edge of trig asserted 
    reg tv_reg = 1;
    assign tv = tv_reg;
    always @ (posedge ad9914_trig_1) begin
        if (tv_mode == 2'b11) begin
            tv_reg <= ~tv_reg;
        end
        else begin
            tv_reg <= 1'b0;
        end
    end

endmodule
