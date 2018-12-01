`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Jordan Elliott
//
// accelX gives the rotation along the X direction (front to back facing the board)
// accelY gives the rotation along the Y direction (left to right facing the board)
// accelTmp gives the temperature (don't need it)
//
// The accelX and accelY values are 9-bit values, ranging from 9'h 000 to 9'h 1FF
//////////////////////////////////////////////////////////////////////////////////


module accelerometer(
    input wire clk,     //use 100MHz clock
    
    //Accelerometer signals
    output wire aclSCK,
    output wire aclMOSI,
    input wire aclMISO,
    output wire aclSS,
    
    //Accelerometer data
    output wire [8:0] accelX, accelY,
    output wire [11:0] accelTmp
    );
    
    AccelerometerCtl accel(clk, 0, aclSCK, aclMOSI, aclMISO, aclSS, accelX, accelY, accelTmp);
    
endmodule
