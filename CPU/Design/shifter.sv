`timescale 1ns / 1ps

module shifter #(parameter N=32) (
    input wire signed [N-1:0] IN,
    input wire [$clog2(N)-1:0] shamt, // ceiling log base 2
    input wire left, logical,
    output wire [N-1:0] OUT
    );
    
    assign OUT = left ? (IN << shamt) :
                   (logical ? IN >> shamt : IN >>> shamt);

endmodule
