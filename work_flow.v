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

    input tr,
    input prf,

    input cmd_ready,
    output reg cmd_ready_clear,
    output reg update_cmd
);

    //在tr和prf同时1低电平时更新指令
    always @ (posedge clk) begin
        if(!rst) begin
            cmd_ready_clear <= 1'b0;
            update_cmd <= 1'b0;
        end
        else if(tr == 1'b0 && prf == 1'b0 && update_cmd == 1'b0) begin
            if(cmd_ready) begin
                cmd_ready_clear <= 1'b1;
                update_cmd <= 1'b1;
            end
        end
        else begin
            cmd_ready_clear <= 1'b0;
            update_cmd <= 1'b0;
        end
    end

endmodule
