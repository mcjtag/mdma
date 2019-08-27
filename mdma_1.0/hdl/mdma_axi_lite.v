`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 22.08.2019 11:25:15
// Design Name: 
// Module Name: mdma_axi_lite
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

module mdma_axi_lite #(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH= 6
)
(
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	input wire [C_S_AXI_ADDR_WIDTH-1:0]S_AXI_AWADDR,
	input wire [2:0]S_AXI_AWPROT,
	input wire S_AXI_AWVALID,
	output wire S_AXI_AWREADY,
	input wire [C_S_AXI_DATA_WIDTH-1:0]S_AXI_WDATA,
	input wire [(C_S_AXI_DATA_WIDTH/8)-1:0]S_AXI_WSTRB,
	input wire S_AXI_WVALID,
	output wire S_AXI_WREADY,
	output wire [1:0]S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input wire S_AXI_BREADY,
	input wire [C_S_AXI_ADDR_WIDTH-1:0]S_AXI_ARADDR,
	input wire [2:0]S_AXI_ARPROT,
	input wire S_AXI_ARVALID,
	output wire S_AXI_ARREADY,
	output wire [C_S_AXI_DATA_WIDTH-1:0]S_AXI_RDATA,
	output wire [1:0]S_AXI_RRESP,
	output wire S_AXI_RVALID,
	input wire S_AXI_RREADY,
	output wire DMA_MM2S_INIT,
	output wire DMA_S2MM_INIT,
	output wire [C_S_AXI_DATA_WIDTH-1:0]DMA_MM2S_ADDR,
	output wire [C_S_AXI_DATA_WIDTH-1:0]DMA_S2MM_ADDR,
	output wire [C_S_AXI_DATA_WIDTH-1:0]DMA_MM2S_LENGTH,
	output wire [C_S_AXI_DATA_WIDTH-1:0]DMA_S2MM_LENGTH,
	input wire DMA_MM2S_DONE,
	input wire DMA_S2MM_DONE,
	input wire DMA_MM2S_ERROR,
	input wire DMA_S2MM_ERROR,
	output wire DMA_RESET,
	output wire DMA_INTR
);

localparam integer LOC_ADDR_WIDTH = 4;
localparam integer LOC_ADDR_LSB = 2;

localparam DMA_CR_ADDR = 0;
localparam DMA_SR_ADDR = 1;
localparam DMA_IR_ADDR = 2;
localparam DMA_SA_ADDR = 3;
localparam DMA_DA_ADDR = 4;
localparam DMA_SL_ADDR = 5;
localparam DMA_DL_ADDR = 6;

reg [LOC_ADDR_WIDTH-1:0]axi_awaddr;
reg axi_awready;
reg axi_wready;
reg [1:0]axi_bresp;
reg axi_bvalid;
reg [LOC_ADDR_WIDTH-1:0]axi_araddr;
reg axi_arready;
reg [C_S_AXI_DATA_WIDTH-1:0]axi_rdata;
reg [1:0]axi_rresp;
reg axi_rvalid;

wire reg_rden;
wire reg_wren;
reg	[C_S_AXI_DATA_WIDTH-1:0]reg_data_out;
integer byte_index;

reg [C_S_AXI_DATA_WIDTH-1:0]reg_sr;
reg [C_S_AXI_DATA_WIDTH-1:0]reg_ir;
reg [C_S_AXI_DATA_WIDTH-1:0]reg_sa;
reg [C_S_AXI_DATA_WIDTH-1:0]reg_da;
reg [C_S_AXI_DATA_WIDTH-1:0]reg_sl;
reg [C_S_AXI_DATA_WIDTH-1:0]reg_dl;
	
reg dma_init_mm2s;
reg dma_init_s2mm;
reg dma_reset;
	
assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP = axi_bresp;
assign S_AXI_BVALID = axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RDATA = axi_rdata;
assign S_AXI_RRESP = axi_rresp;
assign S_AXI_RVALID = axi_rvalid;
	
assign DMA_MM2S_INIT = dma_init_mm2s;
assign DMA_S2MM_INIT = dma_init_s2mm;
	
assign DMA_MM2S_ADDR = reg_sa;
assign DMA_S2MM_ADDR = reg_da;
assign DMA_MM2S_LENGTH = reg_sl;
assign DMA_S2MM_LENGTH = reg_dl;
assign DMA_INTR = (reg_ir[0] & reg_sr[0]) | 
				  (reg_ir[1] & reg_sr[1]) | 
				  (reg_ir[2] & reg_sr[2]) | 
				  (reg_ir[3] & reg_sr[3]) | 
				  (reg_ir[4] & reg_sr[4]);
assign DMA_RESET = dma_reset;

assign reg_wren = axi_wready & S_AXI_WVALID & axi_awready & S_AXI_AWVALID;
assign reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		dma_init_mm2s <= 1'b0;
		dma_init_s2mm <= 1'b0;
		dma_reset <= 1'b0;
	end else begin
		if ((reg_wren == 1'b1) && (axi_awaddr == DMA_CR_ADDR) && (S_AXI_WSTRB[0] == 1'b1) && (S_AXI_WDATA[0] == 1'b1)) begin
			dma_init_mm2s <= 1'b1;
		end else begin
			dma_init_mm2s <= 1'b0;
		end
	
		if ((reg_wren == 1'b1) && (axi_awaddr == DMA_CR_ADDR) && (S_AXI_WSTRB[0] == 1'b1) && (S_AXI_WDATA[1] == 1'b1)) begin
			dma_init_s2mm <= 1'b1;
		end else begin
			dma_init_s2mm <= 1'b0;
		end
		
		if ((reg_wren == 1'b1) && (axi_awaddr == DMA_CR_ADDR) && (S_AXI_WSTRB[0] == 1'b1)) begin
			dma_reset <= S_AXI_WDATA[2];
		end
	end
end

always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		reg_sr <= 0;
	end else begin
		if (reg_sr[0] == 1'b0) begin
			if (DMA_MM2S_DONE == 1'b1) begin
				reg_sr[0] <= 1'b1;
			end
		end else begin
			if ((reg_wren == 1'b1) && (axi_awaddr == DMA_SR_ADDR) && (S_AXI_WSTRB[0] == 1'b1) && (S_AXI_WDATA[0] == 1'b1)) begin
				reg_sr[0] <= 1'b0;
			end
		end
		
		if (reg_sr[1] == 1'b0) begin
			if (DMA_S2MM_DONE == 1'b1) begin
				reg_sr[1] <= 1'b1;
			end
		end else begin
			if ((reg_wren == 1'b1) && (axi_awaddr == DMA_SR_ADDR) && (S_AXI_WSTRB[0] == 1'b1) && (S_AXI_WDATA[1] == 1'b1)) begin
				reg_sr[1] <= 1'b0;
			end
		end
				
		if (reg_sr[3] == 1'b0) begin
			if (DMA_MM2S_ERROR == 1'b1) begin
				reg_sr[3] <= 1'b1;
			end
		end else begin
			if ((reg_wren == 1'b1) && (axi_awaddr == DMA_SR_ADDR) && (S_AXI_WSTRB[0] == 1'b1) && (S_AXI_WDATA[3] == 1'b1)) begin
				reg_sr[3] <= 1'b0;
			end
		end
								
		if (reg_sr[4] == 1'b0) begin
			if (DMA_S2MM_ERROR == 1'b1) begin
				reg_sr[4] <= 1'b1;
			end
		end else begin
			if ((reg_wren == 1'b1) && (axi_awaddr == DMA_SR_ADDR) && (S_AXI_WSTRB[1] == 1'b1) && (S_AXI_WDATA[0] == 1'b1)) begin
				reg_sr[4] <= 1'b0;
			end
		end
	end
end

always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		axi_awready <= 1'b0;
		axi_awaddr <= 0;
		axi_wready <= 1'b0;
	end else begin
		if ((axi_awready == 1'b0) && (S_AXI_AWVALID == 1'b1) && (S_AXI_WVALID == 1'b1)) begin
			axi_awready <= 1'b1;
		end else begin
			axi_awready <= 1'b0;
		end
				
		if ((axi_awready == 1'b0) && (S_AXI_AWVALID == 1'b1) && (S_AXI_WVALID == 1'b1)) begin
			axi_awaddr <= S_AXI_AWADDR[LOC_ADDR_WIDTH+LOC_ADDR_LSB-1:LOC_ADDR_LSB];
		end

		if ((axi_wready == 1'b0) && (S_AXI_WVALID == 1'b1) && (S_AXI_AWVALID == 1'b1)) begin
			axi_wready <= 1'b1;
		end else begin
			axi_wready <= 1'b0;
		end
	end
end

always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		reg_ir <= 0;
		reg_sa <= 0;
		reg_da <= 0;
		reg_sl <= 0;
		reg_dl <= 0;
	end else begin
		if (reg_wren == 1'b1) begin
			case (axi_awaddr)
			DMA_IR_ADDR:
				for (byte_index = 0; byte_index <= C_S_AXI_DATA_WIDTH/8-1; byte_index = byte_index + 1)
					if (S_AXI_WSTRB[byte_index] == 1'b1)
						reg_ir[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			DMA_SA_ADDR:
				for (byte_index = 0; byte_index < C_S_AXI_DATA_WIDTH/8; byte_index = byte_index + 1)
					if (S_AXI_WSTRB[byte_index] == 1'b1)
						reg_sa[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			DMA_DA_ADDR:
				for (byte_index = 0; byte_index < C_S_AXI_DATA_WIDTH/8; byte_index = byte_index + 1)
					if (S_AXI_WSTRB[byte_index] == 1'b1)
						reg_da[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			DMA_SL_ADDR:
				for (byte_index = 0; byte_index < C_S_AXI_DATA_WIDTH/8; byte_index = byte_index + 1)
					if (S_AXI_WSTRB[byte_index] == 1'b1)
						reg_sl[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			DMA_DL_ADDR:
				for (byte_index = 0; byte_index < C_S_AXI_DATA_WIDTH/8; byte_index = byte_index + 1)
					if (S_AXI_WSTRB[byte_index] == 1'b1)
						reg_dl[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
			default: begin
				reg_ir <= reg_ir;
				reg_sa <= reg_sa;
				reg_da <= reg_da;
				reg_sl <= reg_sl;
				reg_dl <= reg_dl;
			end endcase
		end
	end
end

always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		axi_bvalid <= 1'b0;
		axi_bresp <= 2'b00;
		axi_arready <= 1'b0;
		axi_araddr <= 0;
		axi_rvalid <= 1'b0;
		axi_rresp <= 2'b00;
	end else begin
		if ((axi_awready == 1'b1) && (S_AXI_AWVALID == 1'b1) && (axi_wready == 1'b1) && (S_AXI_WVALID == 1'b1) && (axi_bvalid == 1'b0)) begin
			axi_bvalid <= 1'b1;
			axi_bresp <= 2'b00;
		end else if ((S_AXI_BREADY == 1'b1) && (axi_bvalid == 1'b1)) begin
			axi_bvalid <= 1'b0;
		end
				
		if ((axi_arready == 1'b0) && (S_AXI_ARVALID == 1'b1)) begin
			axi_arready <= 1'b1;
			axi_araddr <= S_AXI_ARADDR[LOC_ADDR_WIDTH+LOC_ADDR_LSB-1:LOC_ADDR_LSB];
		end else begin
			axi_arready <= 1'b0;
		end

		if ((axi_arready == 1'b1) && (S_AXI_ARVALID == 1'b1) && (axi_rvalid == 1'b0)) begin
			axi_rvalid <= 1'b1;
			axi_rresp <= 2'b00;
		end else if ((axi_rvalid == 1'b1) && (S_AXI_RREADY == 1'b1)) begin
			axi_rvalid <= 1'b0;
		end   
	end
end

always @(*) begin
	case (axi_araddr)
	DMA_SR_ADDR: reg_data_out <= reg_sr;
	DMA_IR_ADDR: reg_data_out <= reg_ir;
	DMA_SA_ADDR: reg_data_out <= reg_sa;
	DMA_DA_ADDR: reg_data_out <= reg_da;
	DMA_SL_ADDR: reg_data_out <= reg_sl;
	DMA_DL_ADDR: reg_data_out <= reg_dl;
	default: reg_data_out <= 0;
	endcase
end
	
always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0) begin
		axi_rdata <= 0;
	end else begin
		if (reg_rden == 1'b1) begin
			axi_rdata <= reg_data_out;
		end
	end
end

endmodule
