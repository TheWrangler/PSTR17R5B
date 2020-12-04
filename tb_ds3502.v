`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:16:45 12/03/2020 
// Design Name: 
// Module Name:    tb_ds3502 
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
module tb_ds3502;

    reg clk;
    reg rst;
    reg load;
    reg [7:0] r;
    reg sda_i;

    initial begin
		// Initialize Inputs
		clk = 1'b0;
        rst = 1'b0;
        load = 1'b0;
        r = 8'h05;
        sda_i = 1'b0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        rst = 1'b1;
	end

    always begin
		#(7) 
		clk <= ~clk;
	end

    always begin
        #1000000;

        load = 1'b1;

        #2;

        load = 1'b0; 
    end

    wire busy;
    wire scl;
    wire sda_o;
    wire sda_io_select;
    wire a1;
    wire a0;
    
    ds3502 ds3502_inst
    (
        .clk(clk),
        .rst(rst),

        .load(load),
        .r(r),
        .busy(),

        .a1(a1),
        .a0(a0),

        .scl(scl),
        .sda_o(sda_o),
        .sda_i(sda_i),
        .sda_io_select(sda_io_select)//0-w,1-r
    );


endmodule
