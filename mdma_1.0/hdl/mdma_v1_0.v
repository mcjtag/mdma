`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 22.08.2019 09:23:48
// Design Name: 
// Module Name: mdma_v1_0
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

module mdma_v1_0 #(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter integer C_M_AXI_ADDR_WIDTH = 32,
	parameter integer C_M_AXI_DATA_WIDTH = 32,
	parameter integer C_M_AXI_BURST_LEN = 16,
	parameter integer C_S_AXIS_DATA_WIDTH = 32,
	parameter integer C_M_AXIS_DATA_WIDTH = 32,
	parameter integer C_INTERRUPT_USE = 0,
	parameter integer C_MM2S_CHANNEL = 1,
	parameter integer C_S2MM_CHANNEL = 1
)
(
	/* AXI Clock & Reset */
	input wire aclk,
	input wire aresetn,
	/* AXI-Lite Slave Interface */
	input wire [C_S_AXI_ADDR_WIDTH-1:0]s_axi_awaddr,
	input wire [2:0]s_axi_awprot,
	input wire s_axi_awvalid,
	output wire s_axi_awready,
	input wire [C_S_AXI_DATA_WIDTH-1:0]s_axi_wdata,
	input wire [(C_S_AXI_DATA_WIDTH/8)-1:0]s_axi_wstrb,
	input wire s_axi_wvalid,
	output wire s_axi_wready,
	output wire [1:0]s_axi_bresp,
	output wire s_axi_bvalid,
	input wire s_axi_bready,
	input wire [C_S_AXI_ADDR_WIDTH-1:0]s_axi_araddr,
	input wire [2:0]s_axi_arprot,
	input wire s_axi_arvalid,
	output wire s_axi_arready,
	output wire [C_S_AXI_DATA_WIDTH-1:0]s_axi_rdata,
	output wire [1:0]s_axi_rresp,
	output wire s_axi_rvalid,
	input wire  s_axi_rready,
	/* AXI-Full Master Interface */
	output wire [C_M_AXI_ADDR_WIDTH-1:0]m_axi_araddr,
	output wire [1:0]m_axi_arburst,
	output wire [3:0]m_axi_arcache,
	output wire [3:0]m_axi_arlen,
	output wire [2:0]m_axi_arprot,
	input wire m_axi_arready,
	output wire [2:0]m_axi_arsize,
	output wire m_axi_arvalid,
	input wire [C_M_AXI_DATA_WIDTH-1:0]m_axi_rdata,
	input wire m_axi_rlast,
	output wire m_axi_rready,
	input wire [1:0]m_axi_rresp,
	input wire m_axi_rvalid,
	output wire [C_M_AXI_ADDR_WIDTH-1:0]m_axi_awaddr,
	output wire [1:0]m_axi_awburst,
	output wire [3:0]m_axi_awcache,
	output wire [3:0]m_axi_awlen,
	output wire [2:0]m_axi_awprot,
	input wire m_axi_awready,
	output wire [2:0]m_axi_awsize,
	output wire m_axi_awvalid,
	output wire m_axi_bready,
	input wire [1:0]m_axi_bresp,
	input wire m_axi_bvalid,
	output wire [C_M_AXI_DATA_WIDTH-1:0]m_axi_wdata,
	output wire m_axi_wlast,
	input wire m_axi_wready,
	output wire [C_M_AXI_DATA_WIDTH/8-1:0]m_axi_wstrb,
	output wire m_axi_wvalid,
	/* AXI-Stream Slave Interface, S2MM */
	input wire [C_S_AXIS_DATA_WIDTH-1:0]s_axis_tdata,
	input wire s_axis_tvalid,
	output wire s_axis_tready,
	input wire s_axis_tlast,
	/* AXI-Stream Master Interface, MM2S */
	output wire [C_M_AXIS_DATA_WIDTH-1:0]m_axis_tdata,
	output wire m_axis_tvalid,
	input wire m_axis_tready,
	output wire m_axis_tlast,
	/* Interrupt */
	output wire intr
);

wire dma_mm2s_init;
wire dma_s2mm_init;
wire [C_M_AXI_ADDR_WIDTH-1:0]dma_mm2s_addr;
wire [C_M_AXI_ADDR_WIDTH-1:0]dma_s2mm_addr;
wire [C_M_AXI_DATA_WIDTH-1:0]dma_mm2s_length;
wire [C_M_AXI_DATA_WIDTH-1:0]dma_s2mm_length;
wire dma_mm2s_done;
wire dma_s2mm_done;
wire dma_mm2s_error;
wire dma_s2mm_error;
wire dma_reset;

mdma_axi_lite #(
	.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) mdma_axi_lite_inst (
	.S_AXI_ACLK(aclk),
	.S_AXI_ARESETN(aresetn),
	.S_AXI_AWADDR(s_axi_awaddr),
	.S_AXI_AWPROT(s_axi_awprot),
	.S_AXI_AWVALID(s_axi_awvalid),
	.S_AXI_AWREADY(s_axi_awready),
	.S_AXI_WDATA(s_axi_wdata),
	.S_AXI_WSTRB(s_axi_wstrb),
	.S_AXI_WVALID(s_axi_wvalid),
	.S_AXI_WREADY(s_axi_wready),
	.S_AXI_BRESP(s_axi_bresp),
	.S_AXI_BVALID(s_axi_bvalid),
	.S_AXI_BREADY(s_axi_bready),
	.S_AXI_ARADDR(s_axi_araddr),
	.S_AXI_ARPROT(s_axi_arprot),
	.S_AXI_ARVALID(s_axi_arvalid),
	.S_AXI_ARREADY(s_axi_arready),
	.S_AXI_RDATA(s_axi_rdata),
	.S_AXI_RRESP(s_axi_rresp),
	.S_AXI_RVALID(s_axi_rvalid),
	.S_AXI_RREADY(s_axi_rready),
	.DMA_MM2S_INIT(dma_mm2s_init),
	.DMA_S2MM_INIT(dma_s2mm_init),
	.DMA_MM2S_ADDR(dma_mm2s_addr),
	.DMA_S2MM_ADDR(dma_s2mm_addr),
	.DMA_MM2S_LENGTH(dma_mm2s_length),
	.DMA_S2MM_LENGTH(dma_s2mm_length),
	.DMA_MM2S_DONE(dma_mm2s_done),
	.DMA_S2MM_DONE(dma_s2mm_done),
	.DMA_MM2S_ERROR(dma_mm2s_error),
	.DMA_S2MM_ERROR(dma_s2mm_error),
	.DMA_RESET(dma_reset),
	.DMA_INTR(intr)
);

generate if (C_MM2S_CHANNEL) begin
	mdma_m_axi_full_mm2s #(
		.C_M_AXI_BURST_LEN(C_M_AXI_BURST_LEN),
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
		.C_M_AXIS_DATA_WIDTH(C_M_AXIS_DATA_WIDTH)
	) mdma_m_axi_full_mm2s_inst (
		.M_AXI_ACLK(aclk),
		.M_AXI_ARESETN(aresetn),
		.M_AXI_ARADDR(m_axi_araddr),
		.M_AXI_ARBURST(m_axi_arburst),
		.M_AXI_ARCACHE(m_axi_arcache),
		.M_AXI_ARLEN(m_axi_arlen),
		.M_AXI_ARPROT(m_axi_arprot),
		.M_AXI_ARREADY(m_axi_arready),
		.M_AXI_ARSIZE(m_axi_arsize),
		.M_AXI_ARVALID(m_axi_arvalid),
		.M_AXI_RDATA(m_axi_rdata),
		.M_AXI_RLAST(m_axi_rlast),
		.M_AXI_RREADY(m_axi_rready),
		.M_AXI_RRESP(m_axi_rresp),
		.M_AXI_RVALID(m_axi_rvalid),
		.M_AXIS_TDATA(m_axis_tdata),
		.M_AXIS_TVALID(m_axis_tvalid),
		.M_AXIS_TREADY(m_axis_tready),
		.M_AXIS_TLAST(m_axis_tlast),
		.DMA_INIT(dma_mm2s_init),
		.DMA_DONE(dma_mm2s_done),
		.DMA_ADDR(dma_mm2s_addr),
		.DMA_LENGTH(dma_mm2s_length),
		.DMA_ERROR(dma_mm2s_error),
		.DMA_RESET(dma_reset)
	);
end else begin
	assign dma_mm2s_done = 1'b0;
	assign dma_mm2s_error = 1'b0;
end endgenerate

generate if (C_S2MM_CHANNEL) begin
	mdma_m_axi_full_s2mm #(
		.C_M_AXI_BURST_LEN(C_M_AXI_BURST_LEN),
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
		.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH)
	) mdma_m_axi_full_s2mm_inst (
		.M_AXI_ACLK(aclk),
		.M_AXI_ARESETN(aresetn),
		.M_AXI_AWADDR(m_axi_awaddr),
		.M_AXI_AWBURST(m_axi_awburst),
		.M_AXI_AWCACHE(m_axi_awcache),
		.M_AXI_AWLEN(m_axi_awlen),
		.M_AXI_AWPROT(m_axi_awprot),
		.M_AXI_AWREADY(m_axi_awready),
		.M_AXI_AWSIZE(m_axi_awsize),
		.M_AXI_AWVALID(m_axi_awvalid),
		.M_AXI_BREADY(m_axi_bready),
		.M_AXI_BRESP(m_axi_bresp),
		.M_AXI_BVALID(m_axi_bvalid),
		.M_AXI_WDATA(m_axi_wdata),
		.M_AXI_WLAST(m_axi_wlast),
		.M_AXI_WREADY(m_axi_wready),
		.M_AXI_WSTRB(m_axi_wstrb),
		.M_AXI_WVALID(m_axi_wvalid),
		.S_AXIS_TDATA(s_axis_tdata),
		.S_AXIS_TVALID(s_axis_tvalid),
		.S_AXIS_TREADY(s_axis_tready),
		.S_AXIS_TLAST(s_axis_tlast),
		.DMA_INIT(dma_s2mm_init),
		.DMA_DONE(dma_s2mm_done),
		.DMA_ADDR(dma_s2mm_addr),
		.DMA_LENGTH(dma_s2mm_length),
		.DMA_ERROR(dma_s2mm_error),
		.DMA_RESET(dma_reset)
	);
end else begin
	assign dma_s2mm_done = 1'b0;
	assign dma_s2mm_error = 1'b0;
end endgenerate

endmodule
