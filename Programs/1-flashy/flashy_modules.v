// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// flashy_modules.v

//This file contains all instantiated modules for flashy_top.v




//------------------------------------------------------------------------------------
// This module is a simple counter that can count up to a second
// enable serves as an active low reset and stop holds the value of the timer
// this counter runs at clock speed which is 16MHz if connected to WF_CLK,
// that means that the counter increments every 62.5ns
module timer (
	input clk, enable, stop,
	output reg[26:0] counter
	);
	
	always @(posedge clk)
	begin
		if (!enable)
			counter <= 0;
		else if (stop)
			counter <= counter;
		else
			counter <= counter + 1;
	end
endmodule
