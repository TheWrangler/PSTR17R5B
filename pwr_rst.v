`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:11:19 01/17/2020 
// Design Name: 
// Module Name:    pwr_rst 
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
module pwr_rst
	#(
		parameter [31 : 0] MAIN_CLOCK_PERIOD = 7,
		parameter [31 : 0] PWR_RST_DELAY = 100000000
	)
	(
		input clk,
		output rst
    );
	
	localparam [31 : 0] DELAY_CLCOK_NUM = PWR_RST_DELAY / MAIN_CLOCK_PERIOD;
	
	reg [31 : 0] delay_clock_count = 0;
	reg rst_reg = 0;
	assign rst = rst_reg;
	
	always @ (posedge clk) begin
		if(delay_clock_count < DELAY_CLCOK_NUM) begin
			delay_clock_count <= delay_clock_count + 1;
			rst_reg <= 0;
		end
		else rst_reg <= 1;
	end

	// clk_div clk_div_inst
	// (	// Clock in ports
	// 	.CLK_IN1(clk),      // IN
	// 	// Clock out ports
	// 	.CLK_OUT1(clk_100m),     // OUT
	// 	.LOCKED()
	// );      // OUT
		
endmodule
