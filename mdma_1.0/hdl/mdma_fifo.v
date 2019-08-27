`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 23.08.2019 14:54:13
// Design Name: 
// Module Name: mdma_fifo
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

module mdma_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DATA_DEPTH = 4
)
(
    input wire aclk,
    input wire aresetn,
	input wire [DATA_WIDTH-1:0]s_axis_tdata,
	input wire s_axis_tvalid,
	output wire s_axis_tready,
	input wire s_axis_tlast,
	output wire [DATA_WIDTH-1:0]m_axis_tdata,
	output wire m_axis_tvalid,
	input wire m_axis_tready,
	output wire m_axis_tlast
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

localparam CWIDTH = clogb2(DATA_DEPTH);

reg [DATA_WIDTH:0]data[DATA_DEPTH-1:0];
reg [CWIDTH:0]count;
reg [CWIDTH-1:0]tail;
reg [CWIDTH-1:0]head;

wire fifo_full;
wire fifo_empty;

wire fifo_wr;
wire fifo_rd;

wire [DATA_WIDTH:0]din;
wire [DATA_WIDTH:0]dout;

integer i;

assign din = {s_axis_tlast, s_axis_tdata};
assign dout = data[tail];

assign s_axis_tready = ~fifo_full;
assign m_axis_tdata = dout[DATA_WIDTH-1:0];
assign m_axis_tvalid = ~fifo_empty;
assign m_axis_tlast = dout[DATA_WIDTH];

assign fifo_full = (count == DATA_DEPTH) ? 1'b1 : 1'b0;
assign fifo_empty = (count == 0) ? 1'b1 : 1'b0;

assign fifo_wr = s_axis_tvalid & s_axis_tready;
assign fifo_rd = m_axis_tvalid & m_axis_tready;

always @(posedge aclk) begin
    if (aresetn == 1'b0) begin
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            data[i] <= 0;
        end
        count <= 0;
        tail <= 0;
        head <= 0;
    end else begin
        if (fifo_wr) begin
            data[head] <= din;
            if (head == (DATA_DEPTH - 1)) begin
                head <= 0;
            end else begin
                head <= head + 1;
            end
        end
        
        if (fifo_rd) begin
            if (tail == (DATA_DEPTH - 1)) begin
                tail <= 0;
            end else begin
                tail <= tail + 1;
            end
        end
        
        case ({fifo_wr, fifo_rd})
            2'b01: count <= count - 1;
            2'b10: count <= count + 1;
            default: count <= count;
        endcase
    end
end
endmodule
