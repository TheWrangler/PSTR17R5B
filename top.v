`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:17:59 02/01/2020 
// Design Name: 
// Module Name:    top 
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
module top
(
    input clk,
    input clk_2,

    //spi 
    input spi_sclk,
    input spi_din,

    //控制发射开关和供电开关
    output rf_switch,
    output rf_power_p,
    output rf_power_n,


    //空馈/校准控制，0-校准，1-空馈
    output ct_switch,

    //tv/th切换，1-tv,0-th
    output tvh,

    //接收通道供电控制
    output [2:0] rx_ch_pwr_ctrl,
    //接收通道控制
    output [2:0] rx_ch_ctrl,

    //发射衰减
    output [5:0] tx_att,

    //接收通道增益
    // output [5:0] rx_ch1_att,
    // output [5:0] rx_ch2_att,
    // output [5:0] rx_ch3_att,
    output [2:0] a1,
    output [2:0] a0,
    output [2:0] rx_att_scl,
    inout [2:0] rx_att_sda,
   
    //接收通道移相
    output [5:0] rx_ch1_pha,
    output [5:0] rx_ch2_pha,
    output [5:0] rx_ch3_pha,

    //触发信号输出
    output trig,

    //ad9914_1
    output osk_1,
    input dover_1,
    output dhold_1,
    output io_update_1,
    output master_reset_1,
    output dctrl_1,
    output [2 : 0] profile_select_1,
    output [3 : 0] function_select_1,

    output p_pwd_1,
    output p_rd_1,
    output p_wr_1,
    output [7 : 0] p_addr_1,
    inout [15 : 0] p_data_1,

    //ad9914_2
    output osk_2,
    input dover_2,
    output dhold_2,
    output io_update_2,
    output master_reset_2,
    output dctrl_2,
    output [2 : 0] profile_select_2,
    output [3 : 0] function_select_2,

    output p_pwd_2,
    output p_rd_2,
    output p_wr_2,
    output [7 : 0] p_addr_2,
    inout [15 : 0] p_data_2
);

    ///////////////////////////////////////////////////////////
    //global reset
	wire rst;
    pwr_rst pwr_rst_inst
    (
        .clk(clk),
        .rst(rst)
    );

    ///////////////////////////////////////////////////////////
    // depack mdoule
    wire depack_load;
    wire depack_ready;
    wire depack_crc_err;
    wire [31:0] depack_ftw_lower_1;
    wire [31:0] depack_ftw_upper_1;
    wire [31:0] depack_ftw_lower_2;
    wire [31:0] depack_ftw_upper_2;
    wire [31:0] depack_sweep_step;
    wire [15:0] depack_sweep_rate;
    wire [15:0] depack_pulse_period;
    wire [15:0] depack_resweep_period;
    wire [2:0] depack_mode;
    wire depack_rf_switch;
    wire [5:0] depack_tx_att;
    wire [7:0] depack_rx_ch1_att;
    wire [7:0] depack_rx_ch2_att;
    wire [7:0] depack_rx_ch3_att;
    wire [7:0] depack_rx_ch1_pha;
    wire [7:0] depack_rx_ch2_pha;
    wire [7:0] depack_rx_ch3_pha;
    wire [31:0] depack_ct_period;
    wire [31:0] depack_ys_period;

    depack depack_inst
    (
        .clk(clk),
        .rst(rst),

        //spi 
        .spi_sclk(spi_sclk),
        .spi_din(spi_din),

        //cmd field
        .load(depack_load),
        .crc_err(depack_crc_err),
        .ready(depack_ready),
        .ftw_lower_1(depack_ftw_lower_1),
        .ftw_upper_1(depack_ftw_upper_1),
        .ftw_lower_2(depack_ftw_lower_2),
        .ftw_upper_2(depack_ftw_upper_2),
        .sweep_step(depack_sweep_step),
        .sweep_rate(depack_sweep_rate),
        .pulse_period(depack_pulse_period),
        .resweep_period(depack_resweep_period),
        .mode(depack_mode),
        .rf_switch(depack_rf_switch),
        .tx_att(depack_tx_att),
        .rx_ch1_att(depack_rx_ch1_att),
        .rx_ch2_att(depack_rx_ch2_att),
        .rx_ch3_att(depack_rx_ch3_att),
        .rx_ch1_pha(depack_rx_ch1_pha),
        .rx_ch2_pha(depack_rx_ch2_pha),
        .rx_ch3_pha(depack_rx_ch3_pha),
        .ct_period(depack_ct_period),
        .ys_period(depack_ys_period)
    );

    ///////////////////////////////////////////////////////////////
    wire update_cmd;
    wire [31:0] pulse_clock_num;
    wire [31:0] sweep_clock_num;
    wire [31:0] ys_clock_num;
    wire [31:0] ct_clock_num;
    wire tr;
    wire [1:0] tr_edge;
    wire prf;
    wire [1:0] prf_edge;
    wire ct;
    prf_gen prf_gen_inst
    (
        .clk(clk),
        .rst(rst),
        .update(update_cmd),
        .pulse_clock_num(pulse_clock_num),//脉冲宽度时钟周期数
        .sweep_clock_num(sweep_clock_num),//扫频周期时钟周期数
        .ys_clock_num(ys_clock_num),   //触发延时时钟周期数
        .ct_clock_num(ct_clock_num),   //校准时间时钟周期数
        .tr(tr),
        .tr_edge(tr_edge),
        .prf(prf),
        .prf_edge(prf_edge),
        .ct(ct)
    );

    assign pulse_clock_num = {16'h0000,depack_pulse_period} * 3400 / 24;
    assign sweep_clock_num = {16'h0000,depack_resweep_period} * 3400 / 24;
    assign ys_clock_num = depack_ys_period * 3400 / 24;
    assign ct_clock_num = depack_ct_period * 3400 * 1000 / 24;
    assign trig = tr;

    ////////////////////////////////////////////////////////////
    work_flow work_flow_inst
    (
        .clk(clk),
        .rst(rst),

        .tr(tr),
        .prf(prf),

        .cmd_ready(depack_ready),
        .cmd_ready_clear(depack_load),
        .update_cmd(update_cmd)
    );

    ////////////////////////////////////////////////////////////
    wire ad9914_sweep;
    wire ad9914_load;
    wire [31:0] ftw_lower_1;
    wire [31:0] ftw_upper_1;
    wire [31:0] ftw_lower_2;
    wire [31:0] ftw_upper_2;
    wire [31:0] sweep_step;
    wire [15:0] sweep_rate;
    wire [7:0] rx_ch1_att;
    wire [7:0] rx_ch2_att;
    wire [7:0] rx_ch3_att;
    wire rf_power;
    wire rx_att_load;
    cmd_update cmd_update_inst
    (
        .clk(clk),
        .rst(rst),
        .update_cmd(update_cmd),

        .tr_edge(tr_edge),
        .prf_edge(prf_edge),
        .ct(ct),

        .depack_ftw_lower_1(depack_ftw_lower_1),
        .depack_ftw_upper_1(depack_ftw_upper_1),
        .depack_ftw_lower_2(depack_ftw_lower_2),
        .depack_ftw_upper_2(depack_ftw_upper_2),
        .depack_sweep_step(depack_sweep_step),
        .depack_sweep_rate(depack_sweep_rate),

        .depack_mode(depack_mode),
        .depack_rf_switch(depack_rf_switch),
        .depack_tx_att(depack_tx_att),
        .depack_rx_ch1_att(depack_rx_ch1_att),
        .depack_rx_ch2_att(depack_rx_ch2_att),
        .depack_rx_ch3_att(depack_rx_ch3_att),
        .depack_rx_ch1_pha(depack_rx_ch1_pha),
        .depack_rx_ch2_pha(depack_rx_ch2_pha),
        .depack_rx_ch3_pha(depack_rx_ch3_pha),


        //ad9914参数加载和扫频
        .ad9914_load(ad9914_load),
        .ad9914_sweep(ad9914_sweep),

        //控制发射开关和供电开关
        .rf_switch(rf_switch),
        .rf_power(rf_power),
        
        //空馈/校准控制，0-校准，1-空馈
        .ct_switch(ct_switch),

        //tv/th切换，1-tv,0-th
        .tvh(tvh),

        //接收通道供电控制
        .rx_ch_pwr_ctrl(rx_ch_pwr_ctrl),
        .rx_ch_ctrl(rx_ch_ctrl),

        //发射衰减
        .tx_att(tx_att),

        //接收通道增益
        .rx_ch1_att(rx_ch1_att),
        .rx_ch2_att(rx_ch2_att),
        .rx_ch3_att(rx_ch3_att),
        .rx_att_load(rx_att_load),

        //接收通道移相
        .rx_ch1_pha(rx_ch1_pha),
        .rx_ch2_pha(rx_ch2_pha),
        .rx_ch3_pha(rx_ch3_pha),

        .ftw_lower_1(ftw_lower_1),
        .ftw_upper_1(ftw_upper_1),
        .ftw_lower_2(ftw_lower_2),
        .ftw_upper_2(ftw_upper_2),
        .sweep_step(sweep_step),
        .sweep_rate(sweep_rate)
    );

    assign rf_power_p = rf_power;
    assign rf_power_n = ~rf_power;

    //////////////////////////////////////////////////////////
    wire [2:0] sda_o;
    wire [2:0] sda_i;
    wire [2:0] sda_io_select;
    ds3502 ds3502_inst1
    (
        .clk(clk),
        .rst(rst),

        .load(rx_att_load),
        .r(rx_ch1_att),
        .busy(),

        .a1(a1[0]),
        .a0(a0[0]),

        .scl(rx_att_scl[0]),
        .sda_o(sda_o[0]),
        .sda_i(sda_i[0]),
        .sda_io_select(sda_io_select[0])
    );

    ds3502 ds3502_inst2
    (
        .clk(clk),
        .rst(rst),

        .load(rx_att_load),
        .r(rx_ch2_att),
        .busy(),

        .a1(a1[1]),
        .a0(a0[1]),

        .scl(rx_att_scl[1]),
        .sda_o(sda_o[1]),
        .sda_i(sda_i[1]),
        .sda_io_select(sda_io_select[1])
    );

    ds3502 ds3502_inst3
    (
        .clk(clk),
        .rst(rst),

        .load(rx_att_load),
        .r(rx_ch3_att),
        .busy(),

        .a1(a1[2]),
        .a0(a0[2]),

        .scl(rx_att_scl[2]),
        .sda_o(sda_o[2]),
        .sda_i(sda_i[2]),
        .sda_io_select(sda_io_select[2])
    );

    genvar i;
    generate 
        for(i=0;i<2;i=i+1) begin
            IOBUF
            #(
                .DRIVE(12), // Specify the output drive strength
                .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
                .IOSTANDARD("DEFAULT"), // Specify the I/O standard
                .SLEW("SLOW") // Specify the output slew rate
            )
            IOBUF_inst
            (
                .I(sda_o[i]),
                .O(sda_i[i]),
                .T(sda_io_select[i]),
                .IO(rx_att_sda[i])
            );
        end
    endgenerate
    //////////////////////////////////////////////////////////
    //ad9914_1
    wire ad9914_busy_1;
    wire ad9914_finish_1;
    wire [15:0] p_data_in_1;
    wire [15:0] p_data_out_1;
    wire p_data_tri_select_1;

    ad9914_ctrl ad9914_ctrl_inst1
	(
		.clk(clk),
        .rst(rst),

        //input update,
        .set(ad9914_load),
        .sweep(ad9914_sweep),
        .sweep_edge(1),//1-positive sweep,0-negitive sweep
        .lower_limit(ftw_lower_1),
        .upper_limit(ftw_upper_1),
        .positive_step(sweep_step),
        .negitive_step(), 
        .positive_rate(sweep_rate),
        .negitive_rate(),
        .att(0),

        .busy(ad9914_busy_1),
        .finish(ad9914_finish_1),

        .dover(dover_1),
        .dhold(dhold_1),
        .io_update(io_update_1),
        .master_reset(master_reset_1),
        .dctrl(dctrl_1),
        .profile_select(profile_select_1),
        .function_select(function_select_1),

        .p_pwd(p_pwd_1),
        .p_rd(p_rd_1),
        .p_wr(p_wr_1),
        .p_addr(p_addr_1),
        .p_data_in(p_data_in_1),
        .p_data_out(p_data_out_1),
        .p_data_tri_select(p_data_tri_select_1)
	);

    assign osk_1 = tr;

    generate 
        for(i=0;i<16;i=i+1) begin
            IOBUF
            #(
                .DRIVE(12), // Specify the output drive strength
                .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
                .IOSTANDARD("DEFAULT"), // Specify the I/O standard
                .SLEW("SLOW") // Specify the output slew rate
            )
            IOBUF_inst
            (
                .I(p_data_out_1[i]),
                .O(p_data_in_1[i]),
                .T(p_data_tri_select_1),
                .IO(p_data_1[i])
            );
        end
    endgenerate

    //////////////////////////////////////////////////////////////
    //ad9914_2
    wire ad9914_busy_2;
    wire ad9914_finish_2;
    wire [15:0] p_data_in_2;
    wire [15:0] p_data_out_2;
    wire p_data_tri_select_2;

     ad9914_ctrl ad9914_ctrl_inst2
	(
		.clk(clk_2),
        .rst(rst),

        //input update,
        .set(ad9914_load),
        .sweep(ad9914_sweep),
        .sweep_edge(1),//1-positive sweep,0-negitive sweep
        .lower_limit(ftw_lower_2),
        .upper_limit(ftw_upper_2),
        .positive_step(sweep_step),
        .negitive_step(), 
        .positive_rate(sweep_rate),
        .negitive_rate(),
        .att(0),

        .busy(ad9914_busy_2),
        .finish(ad9914_finish_2),

        .dover(dover_2),
        .dhold(dhold_2),
        .io_update(io_update_2),
        .master_reset(master_reset_2),
        .dctrl(dctrl_2),
        .profile_select(profile_select_2),
        .function_select(function_select_2),

        .p_pwd(p_pwd_2),
        .p_rd(p_rd_2),
        .p_wr(p_wr_2),
        .p_addr(p_addr_2),
        .p_data_in(p_data_in_2),
        .p_data_out(p_data_out_2),
        .p_data_tri_select(p_data_tri_select_2)
	);
    assign osk_2 = tr;

    generate 
        for(i=0;i<16;i=i+1) begin
            IOBUF
            #(
                .DRIVE(12), // Specify the output drive strength
                .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
                .IOSTANDARD("DEFAULT"), // Specify the I/O standard
                .SLEW("SLOW") // Specify the output slew rate
            )
            IOBUF_inst
            (
                .I(p_data_out_2[i]),
                .O(p_data_in_2[i]),
                .T(p_data_tri_select_2),
                .IO(p_data_2[i])
            );
        end
    endgenerate

    

    ////////////////////////////////////////////////////////////////
    wire [35:0] CONTROL0;
	wire [99:0] TRIG0;

	assign TRIG0[7:0] = {ct,prf,tr,update_cmd,depack_crc_err,depack_load,depack_ready};
    assign TRIG0[14:8] = {rx_ch_ctrl,rf_power_p,rf_switch,ct_switch,tvh};
    assign TRIG0[20:15] = {ad9914_finish_2,ad9914_finish_1,ad9914_busy_2,ad9914_busy_1,ad9914_sweep,ad9914_load};
    assign TRIG0[28:21] = {dctrl_2,io_update_2,dover_2,osk_2,dctrl_1,io_update_1,dover_1,osk_1};
    assign TRIG0[60:29] = ftw_lower_1;
    //assign TRIG0[60:29] = ftw_upper_1;
    //assign TRIG0[60:29] = sweep_step;
    assign TRIG0[68:61] = p_addr_1;
    assign TRIG0[84:69] = p_data_out_1;
    assign TRIG0[87:85] = depack_mode;
    assign TRIG0[93:88] = rx_ch1_att;
    assign TRIG0[99:94] = rx_ch3_pha;

	myila myila_inst (
		.CONTROL(CONTROL0), // INOUT BUS [35:0]
		.CLK(clk), // IN
		.TRIG0(TRIG0) // IN BUS [99:0]
	);

	myicon myicon_inst (
    	.CONTROL0(CONTROL0) // INOUT BUS [35:0]
	);

endmodule