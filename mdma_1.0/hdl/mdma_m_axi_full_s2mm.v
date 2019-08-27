`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 22.08.2019 13:27:58
// Design Name: 
// Module Name: mdma_m_axi_full_s2mm
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

module mdma_m_axi_full_s2mm #(
	parameter integer C_M_AXI_BURST_LEN = 16,
	parameter integer C_M_AXI_ADDR_WIDTH = 32,
	parameter integer C_M_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXIS_DATA_WIDTH = 32
)
(
	input wire M_AXI_ACLK,
	input wire M_AXI_ARESETN,
	output wire [C_M_AXI_ADDR_WIDTH-1:0]M_AXI_AWADDR,
	output wire [1:0]M_AXI_AWBURST,
	output wire [3:0]M_AXI_AWCACHE,
	output wire [3:0]M_AXI_AWLEN,
	output wire [2:0]M_AXI_AWPROT,
	input wire M_AXI_AWREADY,
	output wire [2:0]M_AXI_AWSIZE,
	output wire M_AXI_AWVALID,
	output wire M_AXI_BREADY,
	input wire [1:0]M_AXI_BRESP,
	input wire M_AXI_BVALID,
	output wire	[C_M_AXI_DATA_WIDTH-1:0]M_AXI_WDATA,
	output wire M_AXI_WLAST,
	input wire M_AXI_WREADY,
	output wire [C_M_AXI_DATA_WIDTH/8-1:0]M_AXI_WSTRB,
	output wire M_AXI_WVALID,
	input wire DMA_INIT,
	output wire DMA_DONE,
	input wire [C_M_AXI_ADDR_WIDTH-1:0]DMA_ADDR,
	input wire [C_M_AXI_DATA_WIDTH-1:0]DMA_LENGTH,
	output wire DMA_ERROR,
	input wire DMA_RESET,
	input wire [C_S_AXIS_DATA_WIDTH-1:0]S_AXIS_TDATA,
	input wire S_AXIS_TVALID,
	output wire S_AXIS_TREADY,
	input wire S_AXIS_TLAST
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
localparam integer C_BNUM = C_M_AXI_DATA_WIDTH / C_S_AXIS_DATA_WIDTH;
localparam integer C_WMSK = 2**(C_S_AXIS_DATA_WIDTH / 8) - 1;
localparam integer C_INUM = C_S_AXIS_DATA_WIDTH / 8;

localparam BURST_SIZE = C_M_AXI_BURST_LEN * C_S_AXIS_DATA_WIDTH / 8; 

reg state;

reg [C_M_AXI_ADDR_WIDTH-1:0]axi_awaddr;
reg axi_awvalid;
reg axi_wlast;
reg axi_wvalid;
reg axi_bready;
reg [C_M_AXI_DATA_WIDTH/8-1:0]axi_wstrb;

reg [C_TNUM:0]burst_index;
reg burst_start;
reg burst_active;
wire t_active;
wire init;
reg done;
reg tdone;
reg rlast;
wire llast;
reg [C_M_AXI_DATA_WIDTH-1:0]data_count;
reg [clogb2(C_BNUM):0]bindex;

wire [C_S_AXIS_DATA_WIDTH-1:0]m_axis_tdata;
wire m_axis_tvalid;
wire m_axis_tready;
wire m_axis_tlast;

assign M_AXI_AWADDR = DMA_ADDR + axi_awaddr;
assign M_AXI_AWLEN = C_M_AXI_BURST_LEN - 1;
assign M_AXI_AWSIZE = clogb2(C_S_AXIS_DATA_WIDTH / 8);
assign M_AXI_AWBURST = 2'b01;
assign M_AXI_AWCACHE = 4'b0011;
assign M_AXI_AWPROT = 3'b000;
assign M_AXI_AWVALID = axi_awvalid;
assign M_AXI_WDATA = {C_INUM{m_axis_tdata}};
assign M_AXI_WSTRB = axi_wstrb;
assign M_AXI_WLAST = axi_wlast;
assign M_AXI_WVALID = (rlast == 1'b0) ? (axi_wvalid & m_axis_tvalid) : axi_wvalid;
assign M_AXI_BREADY = axi_bready;

assign t_active = M_AXI_WREADY & M_AXI_WVALID;
assign init = ((DMA_INIT == 1'b1) && (state == 1'b0));

assign DMA_DONE = done;
assign DMA_ERROR = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1];
assign m_axis_tready = (t_active == 1'b1) && (data_count != 0) && (rlast == 1'b0);
assign llast = ((m_axis_tvalid == 1'b1) && (m_axis_tready == 1'b1) && (m_axis_tlast == 1'b1)) | rlast;

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (init == 1'b1) || (DMA_RESET == 1'b1)) begin
		axi_awvalid <= 1'b0;
		axi_awaddr <= 0;
		axi_wvalid <= 1'b0;
		axi_wlast <= 1'b0;
		axi_bready <= 1'b0;
	end else begin
		if ((axi_awvalid == 1'b0) && (burst_start == 1'b1)) begin
			axi_awvalid <= 1'b1;
		end else if ((M_AXI_AWREADY == 1'b1) && (axi_awvalid == 1'b1)) begin
			axi_awvalid <= 1'b0;
		end else begin
			axi_awvalid <= axi_awvalid;
		end
				
		if ((M_AXI_AWREADY == 1'b1) && (axi_awvalid == 1'b1)) begin
			axi_awaddr <= axi_awaddr + BURST_SIZE;
		end
				
		if ((axi_wvalid == 1'b0) && (burst_start == 1'b1)) begin
			axi_wvalid <= 1'b1;
		end else if ((t_active == 1'b1) && (axi_wlast == 1'b1)) begin
			axi_wvalid <= 1'b0;
		end else begin
			axi_wvalid <= axi_wvalid;
		end
				
		if ((((burst_index == (C_M_AXI_BURST_LEN - 2)) && (C_M_AXI_BURST_LEN >= 2)) && (t_active == 1'b1)) || (C_M_AXI_BURST_LEN == 1)) begin
			axi_wlast <= 1'b1;
		end else if (t_active == 1'b1) begin
			axi_wlast <= 1'b0;
		end else if ((axi_wlast == 1'b1) && (C_M_AXI_BURST_LEN == 1)) begin
			axi_wlast <= 1'b0;
		end
				
		if ((M_AXI_BVALID == 1'b1) && (axi_bready == 1'b0)) begin
			axi_bready <= 1'b1;
		end else if (axi_bready == 1'b1) begin
			axi_bready <= 1'b0;
		end
	end
end

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (init == 1'b1) || (DMA_RESET == 1'b1)) begin
		burst_index <= 0;
		burst_active <= 1'b0;
		data_count <= DMA_LENGTH;
		tdone <= 1'b0;
		rlast <= 1'b0;
		bindex <= 0;
		axi_wstrb <= C_WMSK;
	end else begin
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

		if (burst_start == 1'b1) begin
			burst_active <= 1'b1;
		end else if ((M_AXI_BVALID == 1'b1) && (axi_bready == 1'b1)) begin
			burst_active <= 1'b0;
		end
	
		if ((M_AXI_BVALID == 1'b1) && ((data_count == 0) || (llast == 1'b1)) && (axi_bready == 1'b1)) begin
			tdone <= 1'b1;
		end else begin
			tdone <= 1'b0;
		end
		
		if ((m_axis_tvalid == 1'b1) && (m_axis_tready == 1'b1) && (m_axis_tlast == 1'b1)) begin
			rlast <= 1'b1;
		end
		
		if (t_active == 1'b1) begin
			if ((llast == 1'b1) || (data_count <= C_INUM)) begin
				axi_wstrb <= 0;
			end else begin
				if (bindex == (C_BNUM - 1)) begin
					bindex <= 0;
					axi_wstrb <= C_WMSK;
				end else begin
					bindex <= bindex + 1;
					axi_wstrb <= axi_wstrb * (C_WMSK + 1);
				end
			end
		end
	end
end

always @(posedge M_AXI_ACLK) begin
	if ((M_AXI_ARESETN == 1'b0) || (DMA_RESET == 1'b1)) begin
		state <= 1'b0;
		burst_start <= 1'b0;
		done <= 1'b0;
	end else begin
		if (state == 1'b0) begin
			if (init == 1'b1) begin
				state <= 1'b1;
			end
			done <= 1'b0;
		end else begin
			if (tdone == 1'b1) begin
				state <= 1'b0;
				done <= 1'b1;
			end else begin
				if ((axi_awvalid == 1'b0) && (burst_start == 1'b0) && (burst_active == 1'b0)) begin
					burst_start <= 1'b1;
				end else begin
					burst_start <= 1'b0;
				end
			end
		end
	end
end

mdma_fifo #(
	.DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.DATA_DEPTH(C_M_AXI_BURST_LEN)
) mdma_fifo_inst (
	.aclk(M_AXI_ACLK),
	.aresetn(M_AXI_ARESETN),
	.s_axis_tdata(S_AXIS_TDATA),
	.s_axis_tvalid(S_AXIS_TVALID),
	.s_axis_tready(S_AXIS_TREADY),
	.s_axis_tlast(S_AXIS_TLAST),
	.m_axis_tdata(m_axis_tdata),
	.m_axis_tvalid(m_axis_tvalid),
	.m_axis_tready(m_axis_tready),
	.m_axis_tlast(m_axis_tlast)
);

endmodule
