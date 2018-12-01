`timescale 1ns / 1ps
`default_nettype none

module datapath #(
     parameter Nloc = 32,                          // Number of memory locations
     parameter Dbits = 32                          // Number of bits in data
     //parameter initfile = "...  .mem"
)(
    input wire clk, reset, enable,
    output wire [31:0] pc,
    input wire [31:0] instr, 
    input wire [1:0] pcsel, wasel, wdsel, asel,
    input wire sext, bsel, werf,
    input wire [4:0] alufn,
    input wire [Dbits-1:0] mem_readdata,
    output wire Z,
    output wire [Dbits-1:0] mem_addr,
    output wire [Dbits-1:0] mem_writedata
    );
    
    logic [Dbits-1:0] pcReg = 32'h00400000;
    wire [Dbits-1:0] ReadData1, ReadData2, alu_result;
    wire [Dbits-1:0] pcPlus4 = pcReg + 4;
    wire [25:0] J = instr[25:0];
    wire [15:0] imm = instr[15:0];
    wire [4:0] shamt = instr[10:6];
    wire [4:0] rs = instr[25:21];
    wire [4:0] rt = instr[20:16];
    wire [4:0] rd = instr[15:11];
    wire N, C, V;
    wire [Dbits-1:0] JT = ReadData1;
    wire [4:0] reg_writeaddr = (wasel == 2'b00) ? rd
                             : (wasel == 2'b01) ? rt
                             : 31; // wasel == 2
    wire [Dbits-1:0] reg_writedata = (wdsel == 2'b00) ? pcPlus4
                                   : (wdsel == 2'b01) ? alu_result
                                   : mem_readdata; // wdsel == 2
    wire [Dbits-1:0] signImm = (sext == 1'b1) ? {{16{imm[15]}}, imm} : {16'b0, imm};
    wire [Dbits-1:0] BT = pcPlus4 + (signImm << 2);
    wire [Dbits-1:0] newPC = (pcsel == 2'b00) ? pcPlus4
                           : (pcsel == 2'b01) ? BT
                           : (pcsel == 2'b10) ? {pc[31:28], J, 2'b00}
                           : JT; // pcsel == 3
    wire [Dbits-1:0] aluA = (asel == 2'b00) ? ReadData1
                          : (asel == 2'b01) ? shamt
                          : 16; // asel == 2                            
    wire [Dbits-1:0] aluB = (bsel == 1'b0) ? ReadData2 : signImm;
    
    always_ff @(posedge clk) begin
        if (reset)
            pcReg <= 32'h0040000;
        else if (enable)
            pcReg <= newPC;
    end
        
    assign pc = pcReg;
    assign mem_writedata = ReadData2;
    assign mem_addr = alu_result;
    
    register_file #(Nloc, Dbits) rf(clk, werf, rs, rt, reg_writeaddr, reg_writedata, ReadData1, ReadData2);
    
    ALU #(Dbits) alu(aluA, aluB, alu_result, alufn, N, C, V, Z);
    
endmodule