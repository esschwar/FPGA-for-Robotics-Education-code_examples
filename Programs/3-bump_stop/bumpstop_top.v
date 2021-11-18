// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// bumpstop_top.v

// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This programs makes the RSLK drive forward until the bumper sensors hit an obstacle



module fpga_top (
	input wire WF_CLK, WF_BUTTON,
	input bump0, bump1, bump2, bump3, bump4, bump5,
	output reg ledFR, ledFL, ledBR, ledBL,
	output wire motorL_pwm, motorR_pwm,
	output reg motorL_en, motorL_dir, motorR_en, motorR_dir
	);
	
// Parameters
	//state machine parameters
	localparam s0 = 2'b00;
	localparam s1 = 2'b01;
	localparam s2 = 2'b10;
	localparam s3 = 2'b11;
	
	
	//pwm parameters for time on values represented by speed percentages
	localparam SPEED25 = 16'd4000;
	
// Register Declaration
	reg[2:0] next_state, current_state = s0;
	
	reg motorL_drive, motorR_drive;
// Module Instantiations
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
			//setup state
			s0: begin
				motorL_en	=1'b0;
				motorL_dir	=1'b0;
				motorL_drive	=1'b0;
				
				motorR_en	=1'b0;
				motorR_dir	=1'b0;
				motorR_drive	=1'b0;
				
				ledFR		=1'b0;
				ledFL		=1'b0;
				ledBR		=1'b0;
				ledBL		=1'b0;
				
				next_state = s1;
			end
			
			//wait for a button press
			s1: begin
				motorL_en	=1'b1;
				motorL_dir	=1'b0;
				motorL_drive	=1'b0;
				
				motorR_en	=1'b1;
				motorR_dir	=1'b0;
				motorR_drive	=1'b0;
				
				ledFR		=1'b0;
				ledFL		=1'b0;
				ledBR		=1'b1;
				ledBL		=1'b1;
				
				if (!WF_BUTTON)
					next_state = s2;
				else
					next_state = s1;
				
				
			end
			
			//move forward once the button is pressed until a bumper is hit
			s2: begin
				motorL_en	=1'b1;
				motorL_dir	=1'b0;
				motorL_drive	=1'b1;
				
				motorR_en	=1'b1;
				motorR_dir	=1'b0;
				motorR_drive	=1'b1;
				
				ledFR		=1'b1;
				ledFL		=1'b1;
				ledBR		=1'b0;
				ledBL		=1'b0;
				
				if (!bump0 || !bump1 || !bump2 || !bump3 || !bump4 || !bump5)
					next_state = s1;
				else
					next_state = s2;
			end
		endcase
	end
endmodule

