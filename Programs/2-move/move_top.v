// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// move_top.v

// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This program flashes the LEDs similar to flashy_top.v, however, here we have added the
// motors to run forward intermittently

module fpga_top (
	input wire WF_CLK, WF_BUTTON, 
	output reg ledFR, ledFL, ledBR, ledBL,
	output wire motorL_pwm, motorR_pwm,
	output reg motorL_en, motorL_dir, motorR_en, motorR_dir
	);
	
	
// Parameters
	//State Parameters
	localparam s0 = 2'b00;
	localparam s1 = 2'b01;
	localparam s2 = 2'b10;
	
	//pwm parameters for time on values represented by speed percentages
	localparam SPEED25 = 16'd4000;
	
// Register Declaration
	reg[2:0] next_state, current_state = s0;
	wire[26:0] timerA, timerB;
	reg timerA_en, timerB_en;
	
	reg motorL_drive, motorR_drive;
	
// Module Instantiations
	//timer instantiations
	timer UA (WF_CLK, timerA_en, 1'bZ, timerA);
	timer UB (WF_CLK, timerB_en, 1'bZ, timerB);
	
	//motor pwm instantiations
	pwm motorL (WF_CLK, motorL_drive, SPEED25, motorL_pwm);
	pwm motorR (WF_CLK, motorR_drive, SPEED25, motorR_pwm);


// Always block

	always @(posedge WF_CLK)
		current_state <= next_state;

// State Machine

	always @(*)
	begin
		casex(current_state)
			//reset state
			s0: begin
				motorL_en	= 1'b0;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				
				motorR_en	= 1'b0;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				timerA_en	= 1'b0;
				timerB_en	= 1'b0;
				
				next_state = s1;
			
			end
			//turn on Back LEDs & turn off motors
			s1: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				
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
			//turn on front leds & move forward
			s2: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
			
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
