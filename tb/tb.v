// Copyright (c) 2020 FPGAcademy
// Please see license at https://github.com/fpgacademy/DESim

`timescale 1ns / 1ns
`default_nettype none

// This testbench is designed to hide the details of using the VPI code

`define QUARTSEC 24'd37148
`define EIGTHSEC 24'd18574
module slowrst(output reg slRst, input wire slClk, input wire rst);
   reg [3:0] cnt = 0;
   wire [3:0] nxtCnt;
   
   always @(posedge slClk or rst) begin
      if (rst)
	cnt <= 1;
      else
	cnt <= nxtCnt;
   end
   
   
   assign nxtCnt = (cnt != 0) ? cnt + 1 : cnt;
   
   assign slRst = |(cnt);
   

endmodule   
   

module slowclk(output reg slClk, 
	       input wire clk, input wire rst);
   reg [23:0] 		  val;
   wire [23:0] nextVal;
   wire        nextSlClk;
   
   
   always @(posedge clk) begin
      if (rst) begin
	 val <= 'b0;
	 slClk <= 'b0;
      end else begin
	 val <= nextVal;
	 slClk <= nextSlClk;
      end
   end
   assign nextVal = (val == `QUARTSEC) ? 0 : val + 1;
   assign nextSlClk = (val < `EIGTHSEC) ? 1 : 0;

endmodule
		   

module tb();
   
   reg             CLOCK_50 = 0; // DE-series 50 MHz clock
   wire 	   CLOCK_250ms;
   
   
   reg [ 3: 0] 	    KEY = 0;      // DE-series pushbutton keys
   reg [ 9: 0] 	    SW = 0;       // DE-series SW switches
   wire [47: 0]     HEX;          // HEX displays (six ports)
   wire [ 9: 0]     LEDR;         // DE-series LEDs
   
   reg 		    key_action = 0;
   reg [ 7: 0] 	    scan_code = 0;
   wire [ 2: 0]     ps2_lock_control;
   wire 	    ps2_clk;
   wire 	    ps2_dat;

   wire [ 7: 0]     VGA_X;        // "VGA" column
   wire [ 6: 0]     VGA_Y;        // "VGA" row
   wire [ 2: 0]     VGA_COLOR;    // "VGA pixel" colour (0-7)
   wire 	    plot;         // "Pixel" is drawn when this is pulsed
   wire [31: 0]     GPIO;         // DE-series 40-pin header

   initial $sim_fpga(CLOCK_50, SW, KEY, LEDR, HEX, key_action, scan_code, 
                     ps2_lock_control, VGA_X, VGA_Y, VGA_COLOR, plot, GPIO);

   reg rst;
   
   slowclk aslclk (.slClk(CLOCK_250ms), .clk(CLOCK_50), .rst(rst));
   wire slRst;
   slowrst aslrst (.slRst(slRst), .slClk(CLOCK_250ms), .rst(rst));
   
       

    // DE-series HEX0, HEX1, ... ports
    wire    [ 6: 0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // create the 50 MHz clock signal
    always #10
        CLOCK_50 <= ~CLOCK_50;

    // connect the single HEX port on "sim_fpga" to the six DE-series HEX ports
    assign HEX[47:40] = {1'b0, HEX0};
    assign HEX[39:32] = {1'b0, HEX1};
    assign HEX[31:24] = {1'b0, HEX2};
    assign HEX[23:16] = {1'b0, HEX3};
    assign HEX[15: 8] = {1'b0, HEX4};
    assign HEX[ 7: 0] = {1'b0, HEX5};

    // the key action should only be active for one cycle.
	// In is set by the VPI, and is unset here.
    always @(posedge CLOCK_50) begin
        if(key_action == 1'b1) begin
            key_action <= 1'b0;
        end
    end

   initial begin
      rst = 0;
      #403;
      rst = 1;
      #200;
      rst = 0;
   end

   lab3 dut 
     (.HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX1(HEX1), .HEX0(HEX0), .LEDR(LEDR), .SW(SW), .clk(CLOCK_250ms), .rst(slRst));
   
   
   keyboard_interface KeyBoard(CLOCK_50, ~KEY[0], 
			       key_action, scan_code, ps2_clk, ps2_dat, ps2_lock_control
			       );



//   always @(SW)
//     $display("%b %b\n", SW, HEX0);
   
endmodule
