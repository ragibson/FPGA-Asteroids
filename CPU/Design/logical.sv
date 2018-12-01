`timescale 1ns / 1ps

module logical #(parameter N=32) (
    input wire [N-1:0] A, B,
    input wire [1:0] op,
    output wire [N-1:0] R
    );
    
    assign R = (op == 2'b00) ? A & B :
               (op == 2'b01) ? A | B :
               (op == 2'b10) ? A ^ B :
               (op == 2'b11) ? ~(A | B) : {N{1'b1}};
               
endmodule
