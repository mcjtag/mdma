`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 22.08.2019 13:25:35
// Design Name: 
// Module Name: mdma_m_axi_full_mm2s
// Project Name: mdma
// Target Devices: 7-series
// Tool Versions: 2018.3
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2019 Dmitry Matyunin
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//////////////////////////////////////////////////////////////////////////////////

module mdma_m_axi_full_mm2s #(
	parameter integer C_M_AXI_BURST_LEN = 16,
	parameter integer C_M_AXI_ADDR_WIDTH = 32,
	parameter integer C_M_AXI_DATA_WIDTH = 32,
	parameter integer C_M_AXIS_DATA_WIDTH = 32
)
(
	input wire M_AXI_ACLK,
	input wire M_AXI_ARESETN,
	output wire [C_M_AXI_ADDR_WIDTH-1:0]M_AXI_ARADDR,
	output wire [1:0]M_AXI_ARBURST,
	output wire [3:0]M_AXI_ARCACHE,
	output wire [3:0]M_AXI_ARLEN,
	output wire [2:0]M_AXI_ARPROT,
	input wire M_AXI_ARREADY,
	output wire [2:0]M_AXI_ARSIZE,
	output wire M_AXI_ARVALID,
	input wire [C_M_AXI_DATA_WIDTH-1:0]M_AXI_RDATA,
	input wire M_AXI_RLAST,
	output wire M_AXI_RREADY,
	input wire [1:0]M_AXI_RRESP,
	input wire M_AXI_RVALID,
	input wire DMA_INIT,
	output wire DMA_DONE,
	input wire [C_M_AXI_ADDR_WIDTH-1:0]DMA_ADDR,
	input wire [C_M_AXI_DATA_WIDTH-1:0]DMA_LENGTH,
	output wire DMA_ERROR,
	input wire DMA_RESET,
	output wire [C_M_AXIS_DATA_WIDTH-1:0]M_AXIS_TDATA,
	output wire M_AXIS_TVALID,
	input wire M_AXIS_TREADY,
	output wire M_AXIS_TLAST
);

function integer clogb2;
    input [31:0]value;
    begin
        value = value - 1;
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

localparam integer C_TNUM = clogb2(C_M_AXI_BURST_LEN - 1);
localparam integer C_BNUM = C_M_AXI_DATA_WIDTH / C_M_AXIS_DATA_WIDTH;
localparam integer C_INUM = C_M_AXIS_DATA_WIDTH / 8;

localparam BURST_SIZE = C_M_AXI_BURST_LEN * C_M_AXIS_DATA_WIDTH / 8;

reg [C_M_AXI_ADDR_WIDTH-1:0]axi_araddr;
reg axi_arvalid;
reg axi_rready;

reg state;
reg [C_TNUM:0]burst_index;
reg burst_active;
reg burst_start;
wire t_active;

wire init;
reg done;
reg tdone;
reg [C_M_AXI_DATA_WIDTH-1:0]data_count;
reg [clogb2(C_BNUM)-1:0]bindex;

wire [C_M_AXIS_DATA_WIDTH-1:0]s_axis_tdata;
wire s_axis_tvalid;
wire s_axis_tready;
wire s_axis_tlast;

assign M_AXI_ARADDR = DMA_ADDR + axi_araddr;
assign M_AXI_ARLEN = C_M_AXI_BURST_LEN - 1;
assign M_AXI_ARSIZE = clogb2(C_M_AXIS_DATA_WIDTH / 8);
assign M_AXI_ARBURST = 2'b01;
assign M_AXI_ARCACHE = 4'b0011;
assign M_AXI_ARPROT = 3'b000;
assign M_AXI_ARVALID = axi_arvalid;
assign M_AXI_RREADY = axi_rready & s_axis_tready;

assign t_active = M_AXI_RVALID & M_AXI_RREADY;
assign init = (DMA_INIT == 1'b1) && (state == 1'b0);
assign DMA_DONE = done;
assign DMA_ERROR = M_AXI_RREADY & M_AXI_RVALID & M_AXI_RRESP[1];
assign s_axis_tdata = M_AXI_RDATA[C_M_AXIS_DATA_WIDTH*(bindex+1)-1-:C_M_AXIS_DATA_WIDTH];
assign s_axis_tvalid = (t_active == 1'b1) && (data_count != 0);
assign s_axis_tlast = (data_count == C_INUM) ? 1'b1 : 1'b0;

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (init == 1'b1) || (DMA_RESET == 1'b1)) begin
		axi_arvalid <= 1'b0;
		axi_araddr <= 0;
		axi_rready <= 1'b0;
	end else begin
		if ((axi_arvalid == 1'b0) && (burst_start == 1'b1)) begin
			axi_arvalid <= 1'b1;
		end else if ((M_AXI_ARREADY == 1'b1) && (axi_arvalid == 1'b1)) begin
			axi_arvalid <= 1'b0;
		end
	
		if ((M_AXI_ARREADY == 1'b1) && (axi_arvalid == 1'b1)) begin
			axi_araddr <= axi_araddr + BURST_SIZE;
		end

		if (M_AXI_RVALID == 1'b1) begin
			if ((M_AXI_RLAST == 1'b1) && (axi_rready == 1'b1)) begin
				axi_rready <= 1'b0;
			end else begin
				axi_rready <= 1'b1;
			end
		end
	end
end

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (init == 1'b1) || (DMA_RESET == 1'b1)) begin
		burst_active <= 1'b0;
		data_count <= DMA_LENGTH;
		tdone <= 1'b0;
		burst_index <= 0;
		bindex <= 0;
	end else begin
		if (burst_start == 1'b1) begin
			burst_active <= 1'b1;
		end else if ((t_active == 1'b1) && (M_AXI_RLAST == 1'b1)) begin
			burst_active <= 1'b0;
		end

		if (t_active == 1'b1) begin
			if (data_count != 0) begin
				data_count <= data_count - C_INUM;
			end
		end
				
		if (burst_start == 1'b1) begin
			burst_index <= 0;
		end else begin
			if ((t_active == 1'b1) && (burst_index != (C_M_AXI_BURST_LEN - 1))) begin
				burst_index <= burst_index + 1;
			end
		end
				
		if ((t_active == 1'b1) && (burst_index == (C_M_AXI_BURST_LEN - 1)) && (data_count <= C_INUM)) begin
			tdone <= 1'b1;
		end else begin
			tdone <= 1'b0;
		end

		if (t_active == 1'b1) begin
			if (bindex == (C_BNUM - 1)) begin
				bindex <= 0;
			end  else begin
				bindex <= bindex + 1;
			end
		end
	end
end

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (DMA_RESET)) begin
		state <= 1'b0;
		burst_start <= 1'b0;
		done <= 1'b0;
	end else begin
		if (state == 1'b0) begin
			if (DMA_INIT == 1'b1) begin
				state <= 1'b1;
			end
			done <= 1'b0;
		end else begin
			if (tdone == 1'b1) begin
				state <= 1'b0;
				done <= 1'b1;
			end else begin
				if ((axi_arvalid == 1'b0) && (burst_active == 1'b0) && (burst_start == 1'b0)) begin
					burst_start <= 1'b1;
				end else begin
					burst_start <= 1'b0;
				end
			end
		end
	end
end

mdma_fifo #(
	.DATA_WIDTH(C_M_AXIS_DATA_WIDTH),
    .DATA_DEPTH(C_M_AXI_BURST_LEN)
) mdma_fifo_inst (
	.aclk(M_AXI_ACLK),
	.aresetn(M_AXI_ARESETN),
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tvalid(s_axis_tvalid),
	.s_axis_tready(s_axis_tready),
	.s_axis_tlast(s_axis_tlast),
	.m_axis_tdata(M_AXIS_TDATA),
	.m_axis_tvalid(M_AXIS_TVALID),
	.m_axis_tready(M_AXIS_TREADY),
	.m_axis_tlast(M_AXIS_TLAST)
);

endmodule
