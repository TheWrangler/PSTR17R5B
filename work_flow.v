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
    input ad9914_update_1,
    input ad9914_update_2,
    input ad9914_osk_2_temp,
    input ad9914_trig_1,
    input ad9914_pre_trig_1,
    input [2:0] rx_ch_pwr_ctrl,

    output ad9914_osk_2,
    output tr,
    output tr_pwr,
    output lo,
    output tv,
    output [2:0] rx_ch_ctrl
);

    reg [1:0] ad9914_update_1_edge = 0;
    reg [1:0] ad9914_update_2_edge = 0;
    reg [1:0] ad9914_trig_1_edge = 0;
    reg [1:0] ad9914_pre_trig_1_edge = 0;
    always @ (posedge clk) begin
        ad9914_update_1_edge <= {ad9914_update_1_edge[0],ad9914_update_1};
        ad9914_update_2_edge <= {ad9914_update_2_edge[0],ad9914_update_2};
        ad9914_trig_1_edge <= {ad9914_trig_1_edge[0],ad9914_trig_1};
        ad9914_pre_trig_1_edge <= {ad9914_pre_trig_1_edge[0],ad9914_pre_trig_1};
    end

    ////////////////////////////////////////////////////////////////
    // CT work flow,tr
    //when CT enabled, enable dds2,sweep ct_period then disable osk2
    reg ct_enable = 1'b0;
    reg [31:0] ct_delay_count = 32'h0000_0000;
    reg [31:0] ct_period_reg;
    reg [5:0] ct_fsm_sta = 0;
    always @ (posedge clk) begin
        if(!rst) begin
            ct_delay_count <= 32'd0;
            ct_enable <= 1'b0;
            ct_fsm_sta <= 0;
        end
        else if(ad9914_update_2_edge == 2'b01) begin
            ct_enable <= 1'b1;
            ct_period_reg <= ct_period;
            ct_delay_count <= 0;
        end
        else if(ct_delay_count > ct_period_reg) begin
            ct_enable <= 1'b0;
        end
        else if(ct_enable) begin
            ct_delay_count <= ct_delay_count + 8'd1;
        end
    end

    ///////////////////////////////////////////////////////////
    // tv/th,tr,tr_pwr
    reg [7:0] tv_sw_count = 8'd0;
    reg tv_sw = 1'b1; 
    reg tv_sw_enable = 1'b0;
    reg tr_sw = 1'b0;
    always @ (posedge clk) begin
        if(!rst) begin
            tv_sw_count <= 8'd0;
            tv_sw <= 1'b1;
            tv_sw_enable <= 1'b0;
            tr_sw <= 1'b0;
        end
        else if(ad9914_update_1_edge == 2'b01) begin
            tv_sw_count <= 8'd0;
            tv_sw <= 1'b1;
            tv_sw_enable <= 1'b1;
        end
        else if(ad9914_pre_trig_1_edge == 2'b01) begin
            tv_sw_count <= 8'd0;
            tv_sw_enable <= 1'b1;
        end
        else if(tv_sw_count > 8'd10) begin
            if(tv_mode == 2'b11)
                tv_sw <= ~tv_sw;
            else tv_sw <= 1'b0;
            tv_sw_enable <= 1'b0;
            tv_sw_count <= 8'd0;
            tr_sw <= ct_enable ? 1'b1 : 1'b0;
        end
        else if(tv_sw_enable) begin
            tv_sw_count <= tv_sw_count + 8'd1;
        end
    end

    reg [7:0] tr_pwr_off_count = 8'd0;
    reg tr_pwr_on = 1'b0;
    reg tr_pwr_enable = 1'b0;
    always @ (posedge clk) begin
        if(!rst) begin
            tr_pwr_off_count <= 8'd0;
            tr_pwr_on <= 1'b0;
            tr_pwr_enable <= 1'b0;
        end
        else if((ad9914_update_1_edge == 2'b01) || (ad9914_pre_trig_1_edge == 2'b01)) begin
            tr_pwr_off_count <= 8'd0;
            tr_pwr_on <= 1'b0;
            tr_pwr_enable <= 1'b1;
        end
        else if(ad9914_trig_1_edge == 2'b10) begin
            tr_pwr_on <= 1'b0;
            tr_pwr_enable <= 1'b0;
            tr_pwr_off_count <= 8'd0;
        end
        else if(tr_pwr_off_count > 8'd20) begin
            tr_pwr_on <= 1'b1;
            tr_pwr_enable <= 1'b0;
        end
        else if(tr_pwr_enable) begin
            tr_pwr_off_count <= tr_pwr_off_count + 8'd1;
        end
    end

    assign tv = tv_sw;

    assign tr_pwr = tr_pwr_on;
    assign tr = tr_sw;
    assign lo = tr;

    ////////////////////////////////////////////////////////////
    // osk_2,rx_ch_ctrl
    assign ad9914_osk_2 = ct_enable ? ad9914_osk_2_temp : 1'b0;
    assign rx_ch_ctrl = ct_enable ? rx_ch_pwr_ctrl : 3'b000;

    wire [35:0] CONTROL0;
	wire [99:0] TRIG0;
	assign TRIG0[0] = ad9914_update_1;
	assign TRIG0[1] = ad9914_update_2;
	assign TRIG0[2] = ad9914_osk_2_temp;
	assign TRIG0[3] = ad9914_trig_1;
	assign TRIG0[4] = ad9914_pre_trig_1;
	assign TRIG0[7:5] = rx_ch_pwr_ctrl;
	assign TRIG0[8] = ct_enable;
    assign TRIG0[9] = tv_sw_enable;
    assign TRIG0[10] = tv_sw;
    assign TRIG0[11] = tr_sw;
    assign TRIG0[12] = tr_pwr_on;
    assign TRIG0[13] = tr_pwr_enable;
    assign TRIG0[15:14] = ad9914_update_1_edge;
    assign TRIG0[17:16] = ad9914_update_2_edge;
    assign TRIG0[19:18] = ad9914_trig_1_edge;
    assign TRIG0[21:20] = ad9914_pre_trig_1_edge;

	myila myila_inst (
		.CONTROL(CONTROL0), // INOUT BUS [35:0]
		.CLK(clk), // IN
		.TRIG0(TRIG0) // IN BUS [99:0]
	);

	myicon myicon_inst (
    	.CONTROL0(CONTROL0) // INOUT BUS [35:0]
	);

endmodule
