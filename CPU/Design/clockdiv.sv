//////////////////////////////////////////////////////////////////////////////////
//
// Montek Singh
// 4/5/2018 
//
// The module below takes as input the 100 MHz system clock from the board, and
//   produces several clock outputs with the following frequencies:
//   clk100: 100 MHz
//   clk50:   50 MHz
//   clk25:   25 MHz
//   clk12:   12.5 MHz
//
// For Comp541 final projects, the 12.5 MHz clock should be slow enough to work
//   with all designs.  But for simulation purposes, please use the 100 MHz clock.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module clockdivider_Nexys4(input wire clkin, output wire clk100, clk50, clk25, clk12);

   wire clkout0, clkout1, clkout2, clkout3, clkfbout, locked, clkin, clkfbin;

   MMCME2_BASE #(.CLKOUT0_DIVIDE_F(10), .CLKOUT1_DIVIDE(20), .CLKOUT2_DIVIDE(40), .CLKOUT3_DIVIDE(80),
            .CLKFBOUT_MULT_F(10), .CLKIN1_PERIOD(10.0)) 
            mmcm (.CLKOUT0(clkout0), .CLKOUT1(clkout1), .CLKOUT2(clkout2), .CLKOUT3(clkout3),
               .CLKFBOUT(clkfbout), .LOCKED(locked), .CLKIN1(clkin), .PWRDWN(1'b0),
               .RST(1'b0), .CLKFBIN(clkfbin));


   BUFG   bufclkfb (.I(clkfbout), .O(clkfbin));

   localparam N=2;
   logic [N:0] start_cnt=0;           // Count 2^N clock cycles of 100 MHz clock
   wire clock_enable=locked & start_cnt[N];  // Delay clock outputs by 2^N clock cycles of 100 MHz clock after lock
   always_ff @(posedge clkout0) begin
      if (locked & (start_cnt[N] != 1'b1))
         start_cnt <= start_cnt + 1'b1;
   end

   wire not_clock_enable;
   INV I1 (.I(clock_enable), .O(not_clock_enable));
   BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) buf100 (.O(clk100), .I0(clkout0), .I1(1'b0), .S(not_clock_enable));
   BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) buf50  (.O(clk50),  .I0(clkout1), .I1(1'b0), .S(not_clock_enable));
   BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) buf25  (.O(clk25),  .I0(clkout2), .I1(1'b0), .S(not_clock_enable));
   BUFGMUX #(.CLK_SEL_TYPE("ASYNC")) buf12  (.O(clk12),  .I0(clkout3), .I1(1'b0), .S(not_clock_enable));
   
endmodule
