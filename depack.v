`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:48:57 01/21/2020 
// Design Name: 
// Module Name:    depack
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
module depack
(
    input clk,
    input rst,

    //spi 
    input spi_sclk,
    input spi_din,

    //cmd field
    input load,
    output crc_err,
    output ready,
    output [31:0] ftw_lower_1,
    output [31:0] ftw_upper_1,
    output [31:0] ftw_lower_2,
    output [31:0] ftw_upper_2,
    output [31:0] sweep_step,
    output [15:0] sweep_rate,
    output [15:0] pulse_period,//us
    output [23:0] resweep_period,//us
    output [2:0] mode,
    output rf_switch,
    output [5:0] tx_att,
    output [7:0] rx_ch1_att,
    output [7:0] rx_ch2_att,
    output [7:0] rx_ch3_att,
    output [7:0] rx_ch1_pha,
    output [7:0] rx_ch2_pha,
    output [7:0] rx_ch3_pha,
    output [31:0] ct_period,//ms
    output [31:0] ys_period //us
);

    localparam cmd_frame_size = 46;

    wire fifo_rst = ~rst;
    wire fifo_wr_en;
    wire fifo_rd_en;
    wire [7:0] fifo_din;
    wire [7:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;

    reg fifo_rd_en_reg = 0;
    assign fifo_rd_en = fifo_rd_en_reg;

    myfifo rx_fifo_inst
    (
        .clk(clk), // input clk
        .srst(fifo_rst), // input rst
        .din(fifo_din), // input [7 : 0] din
        .wr_en(fifo_wr_en), // input wr_en
        .rd_en(fifo_rd_en), // input rd_en
        .dout(fifo_dout), // output [7 : 0] dout
        .full(fifo_full), // output full
        .empty(fifo_empty) // output empty
    );

    spi_slave_r spi_slave_r_inst
    (
        .rst(rst),
        .clk(clk),

        //fifo
        .fifo_full(fifo_full),
        .fifo_d(fifo_din),
        .fifo_w_en(fifo_wr_en),

        //spi slave
        .sclk(spi_sclk),
        .sdin(spi_din)
    );

    reg [7:0] cmd [45:0];
    
    assign ftw_lower_1 = {cmd[2],cmd[3],cmd[4],cmd[5]};
    assign ftw_upper_1 = {cmd[6],cmd[7],cmd[8],cmd[9]};
    assign ftw_lower_2 = {cmd[10],cmd[11],cmd[12],cmd[13]};
    assign ftw_upper_2 = {cmd[14],cmd[15],cmd[16],cmd[17]};
    assign sweep_step = {cmd[18],cmd[19],cmd[20],cmd[21]};
    assign sweep_rate = {cmd[22],cmd[23]};
    assign pulse_period = {cmd[24],cmd[25]};
    assign resweep_period = {cmd[26],cmd[27],cmd[28]};
    assign mode = cmd[30][2:0];
    assign rf_switch = cmd[30][3];
    assign tx_att = cmd[29];
    assign rx_ch1_att = cmd[31];
    assign rx_ch2_att = cmd[32];
    assign rx_ch3_att = cmd[33];
    assign rx_ch1_pha = cmd[34];
    assign rx_ch2_pha = cmd[35];
    assign rx_ch3_pha = cmd[36];
    assign ct_period = {cmd[37],cmd[38],cmd[39],cmd[40]};
    assign ys_period = {cmd[41],cmd[42],cmd[43],cmd[44]};

    reg crc_err_reg = 0;
    reg ready_reg = 0;
    assign crc_err = crc_err_reg;
    assign ready = ready_reg;

    reg [4:0] sta_cur = 0;
    reg [7:0] acc_res = 0;
    reg [5:0] byte_index = 0;
    
    always @ (posedge clk) begin
        if(!rst) begin
            crc_err_reg <= 0;
            ready_reg <= 0;
            sta_cur <= 0;
        end
        else begin
            case (sta_cur)
                0 : begin
                    byte_index <= 0;
                    acc_res <= 0;
                    sta_cur <= 1;
                end
                1 : begin
                    if(fifo_empty == 0)
                        sta_cur <=2;
                end
                2 : begin
                    fifo_rd_en_reg <= 1;
                    sta_cur <= 3;
                end
                3 : begin
                    fifo_rd_en_reg <= 0;
                    sta_cur <= 4;
                end
                4 : begin
                    cmd[byte_index] <= fifo_dout;
                    byte_index <= byte_index + 1;
                    sta_cur <= 5;
                end
                5 : begin
                    if(byte_index != cmd_frame_size) 
                        sta_cur <= 1;
                    else begin
                        byte_index <= 0;
                        if((cmd[0] == 8'heb) && (cmd[1] == 8'h90)) begin
                            acc_res <= 0;
                            sta_cur <= 6;
                        end
                        else sta_cur <= 9;
                    end
                end
                6 : begin//计算校验和
                    acc_res <= acc_res + cmd[byte_index];
                    sta_cur <= 7;
                end
                7 : begin
                    byte_index <= byte_index + 1;
                    sta_cur <= 8;
                end
                8 : begin
                    if(byte_index != cmd_frame_size-1)
                        sta_cur <= 6;
                    else begin
                        if(acc_res != cmd[cmd_frame_size-1]) begin
                            crc_err_reg <= 1;
                            byte_index <= 0;
                            sta_cur <= 9;
                        end
                        else begin
                            crc_err_reg <= 0;
                            sta_cur <= 12;
                        end
                    end
                end
                9 : begin//删除到只剩一个字节
                    cmd[byte_index] <= cmd[byte_index+1];
                    sta_cur <= 10;
                end
                10 : begin
                    byte_index <= byte_index + 1;
                    sta_cur <= 11;
                end
                11 : begin
                    if(byte_index != cmd_frame_size-1) 
                        sta_cur <= 9;
                    else sta_cur <= 1;
                end
                12 : begin
                    ready_reg <= 1;
                    sta_cur <= 13;
                end
                13 : begin
                    if(load) begin
                        ready_reg <= 0;  
                        sta_cur <= 0;
                    end
                end
            endcase
        end
    end

    // wire [35:0] CONTROL0;
	// wire [99:0] TRIG0;
	// assign TRIG0[4:0] = sta_cur;
	// assign TRIG0[10:5] = byte_index;
    // assign TRIG0[11] = fifo_wr_en;
    // assign TRIG0[12] = fifo_rd_en;
    // assign TRIG0[20:13] = fifo_din;
    // assign TRIG0[28:21] = fifo_dout;
    // assign TRIG0[29] = fifo_full;
    // assign TRIG0[30] = fifo_empty;
    // assign TRIG0[31] = crc_err;
    // assign TRIG0[32] = ready;

    // assign TRIG0[34] = spi_sclk;
    // assign TRIG0[35] = spi_din;
    // assign TRIG0[67:36] = {cmd[10],cmd[11],cmd[12],cmd[13]};
    // assign TRIG0[99:68] = {cmd[0],cmd[1],cmd[24],cmd[25]};
    

	// myila myila_inst (
	// 	.CONTROL(CONTROL0), // INOUT BUS [35:0]
	// 	.CLK(clk), // IN
	// 	.TRIG0(TRIG0) // IN BUS [99:0]
	// );

	// myicon myicon_inst (
    // 	.CONTROL0(CONTROL0)// INOUT BUS [35:0]
	// );

endmodule
