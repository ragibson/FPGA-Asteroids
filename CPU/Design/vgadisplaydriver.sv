`timescale 1ns / 1ps
`default_nettype none
`include "display640x480.vh"

module vgadisplaydriver #(
    parameter numChars=4,
    parameter Dbits=11,
    parameter initfile = "...  .mem"
)(
    input wire clk,
    input wire [$clog2(numChars)-1:0] charcode,
    output wire [Dbits-1:0] smem_addr,
    output wire [11:0] bmem_color,
    output wire [3:0] red, green, blue,
    output wire hsync, vsync
    );

   wire [`xbits-1:0] x;
   wire [`ybits-1:0] y;
   wire activevideo;

   vgatimer myvgatimer(clk, hsync, vsync, activevideo, x, y);
   
   wire [5:0] row = y[`ybits-1:4]; // size ceil log_2(800 / 16)
   wire [5:0] col = x[`xbits-1:4]; // size ceil log_2(525 / 16)
   assign smem_addr = (row << 5) + (row << 3) + col; // 40*row + col

   wire [3:0] xoffset = x[3:0];
   wire [3:0] yoffset = y[3:0];
   wire [$clog2(16*16*numChars)-1:0] bmem_addr = {charcode, yoffset, xoffset};
   
   rom_module #(16*16*numChars, 12, initfile) mem (bmem_addr, bmem_color);
   
   assign red[3:0]   = (activevideo == 1) ? bmem_color[11:8] : 4'b0;
   assign green[3:0] = (activevideo == 1) ? bmem_color[7:4]  : 4'b0;
   assign blue[3:0]  = (activevideo == 1) ? bmem_color[3:0]  : 4'b0;

endmodule

