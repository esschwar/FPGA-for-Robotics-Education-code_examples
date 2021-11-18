// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// flashy_top.v

// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This program simply flashed the RSLK leds based on a timer

// WARNING: In Werilog files where not all RSLK io are declared in the port list might
// result in unexpected outputs (motors turning on). To avoid this power WebFPGA only
// through USB power.



module fpga_top (
	input wire WF_CLK, WF_BUTTON, 
	output reg ledFR, ledFL, ledBR, ledBL
	);
	
	
// Parameters
	localparam s0 = 2'b00;
	localparam s1 = 2'b01;
	localparam s2 = 2'b10;
// Register Declaration
	reg[2:0] next_state, current_state = s0;
	wire[26:0] timerA, timerB;
	reg timerA_en, timerB_en;
// Module Instantiations

	timer UA (WF_CLK, timerA_en, 1'bZ, timerA);
	timer UB (WF_CLK, timerB_en, 1'bZ, timerB);


// Always block

	always @(posedge WF_CLK)
		current_state <= next_state;
// State Machine

	always @(*)
	begin
		casex(current_state)
			//reset state
			s0: begin
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				timerA_en	= 1'b0;
				timerB_en	= 1'b0;
				
				next_state = s1;
			
			end
			//turn on Back LEDs
			s1: begin
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b1;
				ledBL		= 1'b1;
				timerA_en	= 1'b1;
				timerB_en	= 1'b0;
				
				//move to next state after 1 second
				if (timerA == 16000000)
					next_state = s2;
				else
					next_state = s1;
			end
			//turn on front leds
			s2: begin
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				timerA_en	= 1'b0;
				timerB_en	= 1'b1;
				
				//move to previous state after 1 second
				if (timerB == 16000000)
					next_state = s1;
				else
					next_state = s2;
			end
		endcase
	end
	
endmodule



