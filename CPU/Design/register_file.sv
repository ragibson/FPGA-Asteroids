`timescale 1ns / 1ps
`default_nettype none

module register_file #(
   parameter Nloc = 32,                           // Number of memory locations
   parameter Dbits = 32                           // Number of bits in data
   // parameter initfile = "...  .mem"
)(
   input wire clock,
   input wire wr,                                 // WriteEnable:  if wr==1, data is written into mem
   input wire [$clog2(Nloc)-1 : 0] ReadAddr1, ReadAddr2, WriteAddr,
                                                  // 3 addresses, two for reading and one for writing
   input wire [Dbits-1 : 0] WriteData,            // Data for writing into memory (if wr==1)
   output wire [Dbits-1 : 0] ReadData1, ReadData2 // 2 output ports
   );

   logic [Dbits-1 : 0] rf [Nloc : 0];             // The actual registers where data is stored
   // initial $readmemh(initfile, mem, 0, Nloc-1);   // initial $readmemh(initfile, ..., ..., ...);  
                                                  // Usually no need to initialize register file

   always_ff @(posedge clock)                     // Memory write: only when wr==1, and only at posedge clock
      if(wr)
         rf[WriteAddr] <= WriteData;

   // MODIFY the two lines below so if register 0 is being read, then the output
   // is 0 regardless of the actual value stored in register 0
   
   assign ReadData1 = (ReadAddr1 == 0) ? 0 : rf[ReadAddr1];     // First output port
   assign ReadData2 = (ReadAddr2 == 0) ? 0 : rf[ReadAddr2];     // Second output port
   
endmodule
