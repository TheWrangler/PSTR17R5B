`timescale 1 ns / 1 ns

module spi_slave_r
(
	input rst,
	input clk,
	
	//fifo
	input fifo_full,
	output [7:0] fifo_d,
	output fifo_w_en,
	
	//spi slave
	input sclk,
	input sdin
);

	//sck edge check
	reg [1:0] sclk_edge = 2'b00;

	always @ (posedge clk) begin
		if(!rst) begin
			sclk_edge <= 2'b00;
		end
		else begin
			sclk_edge <= {sclk_edge[0],sclk};
		end
	end

	reg w_en_reg = 0;
	reg [7:0] d_reg = 8'd0;
	assign fifo_w_en = w_en_reg;
	assign fifo_d = d_reg;

	reg [4:0] bit_index = 5'd0;
	reg [4:0] sta_cur = 0;
	always @ (posedge clk) begin
		if(!rst) begin
			w_en_reg <= 1'b0;
			d_reg <= 8'd0;
			bit_index <= 5'd0;

			sta_cur <= 0;
		end
		else begin
			case(sta_cur)
				0 : begin
					d_reg <= 8'd0;
					bit_index <= 5'd0;
					sta_cur <= 1;
				end

				1 : begin
					if(sclk_edge == 2'b01) begin
						d_reg[0] <= sdin;
						sta_cur <= 2;
					end
				end

				2 : begin
					bit_index <= bit_index + 1;
					sta_cur <= 3;
				end	

				3 : begin
					if(bit_index == 8) begin
						if(fifo_full != 1)
							w_en_reg <= 1;
						sta_cur <= 4;
					end
					else begin
						d_reg <= {d_reg[6:0],1'b0};
						sta_cur <= 1;
					end
				end

				4 : begin
					w_en_reg <= 0;
					sta_cur <= 0;
				end
			endcase
		end
			
	end

endmodule