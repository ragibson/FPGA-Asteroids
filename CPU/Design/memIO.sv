`timescale 1ns / 1ps
`default_nettype none

module memIO #(
    parameter numChars = 4,
    parameter Nloc = 16,                      // Number of memory locations
    parameter Dbits = 4,                      // Number of bits in data
    parameter dmem_init = "...  .mem",        // Name of file with initial data values
    parameter smem_init = "...  .mem"         // Name of file with initial screen values
)(
    input wire clock,
    input wire cpu_wr,
    input wire [Dbits-1:0] cpu_addr,
    input wire [Dbits-1:0] cpu_writedata,
    input wire [$clog2(30*40)-1:0] vga_addr,
    input wire [8:0] accelX, accelY,
    input wire [Dbits-1:0] keyb_char,
    output logic [Dbits-1:0] cpu_readdata,         // will become wires because of always_comb
    output logic [15:0] lights = 0,
    output logic unsigned [Dbits-1:0] period = 0,
    output wire [$clog2(numChars)-1:0] vga_readdata
    );
    
    wire lights_wr = cpu_wr && (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b11);
    wire sound_wr = cpu_wr && (cpu_addr[17:16] == 2'b11) && (cpu_addr[3:2] == 2'b10);
    wire smem_wr = cpu_wr && (cpu_addr[17:16] == 2'b10);
    wire dmem_wr = cpu_wr && (cpu_addr[17:16] == 2'b01);
    wire [31:0] accel_val = {7'b0, accelX, 7'b0, accelY};
    wire [$clog2(numChars)-1:0] smem_readdata;
    wire [Dbits-1:0] dmem_readdata;
    
    ram_module #(Nloc, Dbits, dmem_init) mem(clock, dmem_wr, cpu_addr[Dbits-1:2], cpu_writedata, dmem_readdata);
    dual_ram_module #(30*40, $clog2(numChars), smem_init) smem(clock, smem_wr, cpu_addr[Dbits-1:2], cpu_writedata, smem_readdata, vga_addr, vga_readdata);
    
    logic [15:0] LED = 0;
    logic unsigned [31:0] sound = 0;
    
    always_ff @(posedge clock) begin
        if (lights_wr)
            lights <= cpu_writedata;
        if (sound_wr)
            period <= cpu_writedata;
    end
    
    always_comb begin
        if (cpu_addr[17:16] == 2'b01)
            cpu_readdata = dmem_readdata;
        else if (cpu_addr[17:16] == 2'b10)
            cpu_readdata = smem_readdata;
        else if (cpu_addr[17:16] == 2'b11)
            if (cpu_addr[3:2] == 2'b00)
                cpu_readdata = keyb_char;
            else if (cpu_addr[3:2] == 2'b01)
                cpu_readdata = accel_val;
            else
                cpu_readdata = 32'b0;
        else
            cpu_readdata = 32'b0;
    end
endmodule
