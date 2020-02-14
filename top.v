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

    //RF Switch 
    output tr_p,
    output tr_n,
    //tx att.
    output [5:0] tx_att,
    //tx channel switch
    output th,
    output tv,
    //rx power ctrl
    output [2:0] rx_ch_pwr_ctrl,
    //rx chanel att.
    output [5:0] rx_ch1_att,
    output [5:0] rx_ch2_att,
    output [5:0] rx_ch3_att,
    //rx channel pha
    output [5:0] rx_ch1_pha,
    output [5:0] rx_ch2_pha,
    output [5:0] rx_ch3_pha,
    //trig
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
    inout [7 : 0] p_data_1,

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
    inout [7 : 0] p_data_2
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
    wire [31:0] depack_resweep_period;
    wire [1:0] depack_mode;
    wire depack_rf_switch;
    wire [7:0] depack_tx_att;
    wire [2:0] depack_rx_ch_pwr_ctrl;
    wire [7:0] depack_rx_ch1_att;
    wire [7:0] depack_rx_ch2_att;
    wire [7:0] depack_rx_ch3_att;
    wire [7:0] depack_rx_ch1_pha;
    wire [7:0] depack_rx_ch2_pha;
    wire [7:0] depack_rx_ch3_pha;

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
        .resweep_period(depack_resweep_period),
        .mode(depack_mode),
        .rf_switch(depack_rf_switch),
        .tx_att(depack_tx_att),
        .rx_ch_pwr_ctrl(depack_rx_ch_pwr_ctrl),
        .rx_ch1_att(depack_rx_ch1_att),
        .rx_ch2_att(depack_rx_ch2_att),
        .rx_ch3_att(depack_rx_ch3_att),
        .rx_ch1_pha(depack_rx_ch1_pha),
        .rx_ch2_pha(depack_rx_ch2_pha),
        .rx_ch3_pha(depack_rx_ch3_pha)
    );
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    //RF switch
    assign tr_p = depack_rf_switch;
    assign tr_n = ~depack_rf_switch;

    ///////////////////////////////////////////////////////////
    //tx att.
    assign tx_att = depack_tx_att[5:0];

    ///////////////////////////////////////////////////////////
    //tv/th mode
    //

    ///////////////////////////////////////////////////////////
    //rx power ctrl
    assign rx_ch_pwr_ctrl = depack_rx_ch_pwr_ctrl;

    ///////////////////////////////////////////////////////////
    //rx channel att.
    assign rx_ch1_att = depack_rx_ch1_att[5:0];
    assign rx_ch2_att = depack_rx_ch2_att[5:0];
    assign rx_ch3_att = depack_rx_ch3_att[5:0];

    ///////////////////////////////////////////////////////////
    //rx channel pha
    assign rx_ch1_pha = depack_rx_ch1_pha[5:0];
    assign rx_ch2_pha = depack_rx_ch2_pha[5:0];
    assign rx_ch3_pha = depack_rx_ch3_pha[5:0];

    //////////////////////////////////////////////////////////
    //ad9914_1
    wire ad9914_update_1;
    wire ad9914_busy_1;
    wire ad9914_finish_1;
    wire ad9914_trig_1;
    wire [7:0] p_data_in_1;
    wire [7:0] p_data_out_1;
    wire p_data_tri_select_1;
    wire resweep_1;
    ad9914_ctrl ad9914_ctrl_inst1
	(
		.clk(clk),
		.rst(rst),

		.update(ad9914_update_1),
		.lower_limit(depack_ftw_lower_1),
		.upper_limit(depack_ftw_upper_1),
		.positive_step(depack_sweep_step),
		.positive_rate(depack_sweep_rate),
		.resweep_period(depack_resweep_period),

		.busy(ad9914_busy_1),
		.finish(ad9914_finish_1),

		.trig(ad9914_trig_1),
        .resweep(resweep_1),

		.osk(osk_1),
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

	genvar i;
    generate 
        for(i=0;i<8;i=i+1) begin
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
    wire ad9914_update_2;
    wire ad9914_busy_2;
    wire ad9914_finish_2;
    wire ad9914_trig_2;
    wire [7:0] p_data_in_2;
    wire [7:0] p_data_out_2;
    wire p_data_tri_select_2;
    ad9914_ctrl ad9914_ctrl_inst2
	(
		.clk(clk_2),
		.rst(rst),

		.update(ad9914_update_2),
		.lower_limit(depack_ftw_lower_2),
		.upper_limit(depack_ftw_upper_2),
		.positive_step(depack_sweep_step),
		.positive_rate(depack_sweep_rate),
		.resweep_period(depack_resweep_period),

		.busy(ad9914_busy_2),
		.finish(ad9914_finish_2),

		.trig(ad9914_trig_2),
        .resweep(),

		.osk(osk_2),
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

    // assign dctrl_2 = 0;
    // assign dhold_2 = 0;
    // assign p_addr_2 = 0;
    // assign osk_2 = 0;
    // assign p_pwd_2 = 0;
    // assign function_select_2 = 0;
    // assign profile_select_2 = 0;
    // assign p_rd_2 = 0;
    // assign p_wr_2 = 0;
    // assign io_update_2 = 0;
    // assign master_reset_2 = 0;

    generate 
        for(i=0;i<8;i=i+1) begin
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

    //////////////////////////////////////////////////////////////////
    // TV/TH
    // mode=11,switch when falling-edge of trig asserted 
    reg tv_reg = 1;
    reg th_reg = 0;
    assign tv = tv_reg;
    assign th = th_reg;
    always @ (posedge ad9914_trig_1) begin
        if (depack_mode == 2'b11) begin
            tv_reg <= ~tv_reg;
            th_reg <= tv_reg;
        end
        else begin
            tv_reg <= 1'b1;
            th_reg <= 1'b0;
        end
    end

    ////////////////////////////////////////////////////////////////
    // trig
    assign trig = ad9914_trig_1;

    ////////////////////////////////////////////////////////////////
    // CT
    //when CT enabled, switch when falling-edge of trig asserted


    /////////////////////////////////////////////////////////////////
    // main progress
    reg depack_load_reg = 0;
    reg ad9914_update_1_reg = 0;
    reg ad9914_update_2_reg = 0;
    assign depack_load = depack_load_reg;
    assign ad9914_update_1 = ad9914_update_1_reg;
    assign ad9914_update_2 = ad9914_update_2_reg;

    reg [3:0] main_proc_sta = 0;
    always @ (posedge clk) begin
        if(!rst) begin 
            depack_load_reg <= 0;
            ad9914_update_1_reg <= 0;
            ad9914_update_2_reg <= 0;
            main_proc_sta <= 0;
        end
        else begin
            case (main_proc_sta)
                0 : begin
                    if(depack_ready)
                        main_proc_sta <= 1;
                end
                1 : begin
                    ad9914_update_1_reg <= 1;
                    ad9914_update_2_reg <= 1;
                    main_proc_sta <= 2;
                end
                2 : begin
                    if(ad9914_busy_1 && ad9914_busy_2) begin
                        ad9914_update_1_reg <= 0;
                        ad9914_update_2_reg <= 0;
                        main_proc_sta <= 3;
                    end
                end
                3 : begin
                    if(ad9914_finish_1 && ad9914_finish_2)
                        main_proc_sta <= 4;
                end
                4 : begin
                    depack_load_reg <= 1;
                    main_proc_sta <= 5;
                end
                5 : begin
                    if(!depack_ready) begin
                        depack_load_reg <= 0;
                        main_proc_sta <= 0;
                    end
                end
            endcase
        end
    end

    wire [35:0] CONTROL0;
	wire [99:0] TRIG0;
	assign TRIG0[0] = depack_ready;
	assign TRIG0[4:1] = main_proc_sta;
	assign TRIG0[5] = depack_load_reg;
	assign TRIG0[6] = ad9914_update_1;
	assign TRIG0[7] = ad9914_update_1;
	assign TRIG0[8] = ad9914_busy_1;
	assign TRIG0[9] = ad9914_busy_2;
    assign TRIG0[10] = ad9914_finish_1;
    assign TRIG0[11] = ad9914_finish_1;
    assign TRIG0[43:12] = depack_ftw_lower_1;
    assign TRIG0[75:44] = depack_resweep_period;
    assign TRIG0[91:76] = depack_sweep_rate;
    assign TRIG0[93:92] = depack_mode;
    assign TRIG0[96:94] = depack_rx_ch_pwr_ctrl;
    assign TRIG0[97] = trig;

	myila myila_inst (
		.CONTROL(CONTROL0), // INOUT BUS [35:0]
		.CLK(clk), // IN
		.TRIG0(TRIG0) // IN BUS [99:0]
	);

	myicon myicon_inst (
    	.CONTROL0(CONTROL0) // INOUT BUS [35:0]
	);

endmodule
