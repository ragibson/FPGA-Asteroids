//////////////////////////////////////////////////////////////////////////////////
//
// Montek Singh
// 11/18/2015 
//
// This module simply produces a tone of a given period.
//   The tone is produced as a square wave (which approximates a sinusoid).
//   The period (not the frequency) is a 32-bit input, in units of the 100 MHz
//   clock's period, i.e., in units of 10 ns.  Thus, a 1 KHz tone will be
//   specified to have a period of 100,000 because 100,000 * 10 ns = 1 ms,
//   which corresponds to a 1 KHz frequency.
//
// This simple module has a fixed tone volume; only its frequency can be changed.
//   To turn sound off, the parent module can set the audEn signal to 0.
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module montek_sound_Nexys4(
    input wire clock100,
    input wire unsigned [31:0] period,          // sound period in tens of nanoseconds
                                                // period = 1 means 10 ns (i.e., 100 MHz)      
    output logic audPWM
    );
        
    logic unsigned [31:0] count=0;
    
    always_ff @(posedge clock100)
        count <= (count >= period-1)? 0 : count + 1;           // Counter mod period
        
    assign audPWM = (count < (period >> 1));
    
endmodule
