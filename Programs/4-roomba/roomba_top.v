// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// roomba_top.v

// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This specific design allows the robot to avoid an obstacle after colliding it with it.
// The robot will move forward, if it collides on the left it will turn right, the same is
// true for the opposite side.
// The sensors used are the bumper switches and encoders.


module fpga_top (
	input wire WF_CLK, WF_BUTTON,
	input bump0, bump1, bump2, bump3, bump4, bump5,
	input wire motorL_encdr, motorR_encdr,
	output reg ledFR, ledFL, ledBR, ledBL,
	output wire motorL_pwm, motorR_pwm,
	output reg motorL_en, motorL_dir, motorR_en, motorR_dir
	);
	
// Parameters
	//state machine parameters
	localparam s0	= 4'b0000;
	localparam s1	= 4'b0001;
	localparam s2	= 4'b0010;
	localparam s3	= 4'b0011;
	localparam s4	= 4'b0100;
	localparam s5	= 4'b0101;
	localparam s6	= 4'b0110;
	localparam s7	= 4'b0111;
	localparam s8	= 4'b1000;
	localparam s9	= 4'b1001;
	localparam s10	= 4'b1010;
	
	//pwm parameters for time on values represented by speed percentages
	localparam SPEED25 = 16'd4000;
	
	
// Register Declarations
	reg [3:0] next_state, current_state = s0;
	reg motorL_drive, motorR_drive, encoder_en;
	
	wire signed [10:0] revL, degL, revR, degR;
	wire slowclk;
	
// Module Instantiations
	//motor pwm instantiations
	pwm motorL (WF_CLK, motorL_drive, SPEED25, motorL_pwm);
	pwm motorR (WF_CLK, motorR_drive, SPEED25, motorR_pwm);
	
	//2khz clock
	newclock twohzclk(WF_CLK, 1, 16'd8000, slowclk);
	
	//encoder instantiations
	encoder Rwheel (slowclk, motorR_dir, motorR_drive, encoder_en, motorR_encdr, revR, degR);
	encoder Lwheel (slowclk, motorL_dir, motorL_drive, encoder_en, motorL_encdr, revL, degL);
	
// Always Block
	always @(posedge WF_CLK)
		current_state <= next_state;
		
// State Machine

	always @(*) begin
		casex (current_state)
			//reset state
			s0: begin
				motorL_en	= 1'b0;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				
				motorR_en	= 1'b0;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				
				encoder_en	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				next_state = s1;
			end
			
			//stand by state, wait for WF_BUTTON input
			s1: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				
				encoder_en	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!WF_BUTTON)
					next_state = s2;
				else
					next_state = s1;
			end
			
			//move forward and wait for the robot to hit something
			s2: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!bump5 || !bump4 || !bump3)
					next_state = s3;
				else if (!bump2 || !bump1 || !bump0)
					next_state = s6;
				else
					next_state = s2;
			end
			
			// move back until we have reached 1 rotations
			s3: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b1;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b1;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b1;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b1;
				ledBL		= 1'b1;
				
				if ((revR == -11'sd1) || (revL == -11'sd1))
					next_state = s4;
				else
					next_state = s3;
			end
			
			// clear encoder we are going to spin right
			s4: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b1;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b1;
				ledBR		= 1'b1;
				ledBL		= 1'b0;
				
				next_state = s5;
			end
			
			// make a half turn towards the right
			s5: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b1;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b1;
				
				ledFR		= 1'b0;
				ledFL		= 1'b1;
				ledBR		= 1'b1;
				ledBL		= 1'b0;
				
				if ((degR == -11'sd180) || (degL == 11'sd180))
					next_state = s2;
				else
					next_state = s5;
			end
			
			// move back until we have reached 1 rotations
			s6: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b1;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b1;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b1;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b1;
				ledBL		= 1'b1;
				
				if ((revR == -11'sd1) || (revL == -11'sd1))
					next_state = s7;
				else
					next_state = s6;
			end
			
			// clear encoder we are going to spin right
			s7: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b1;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b1;
				
				next_state = s8;
			end
			
			// make a half turn towards the right
			s8: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b1;
				motorL_drive	= 1'b1;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				
				encoder_en	= 1'b1;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b1;
				
				if ((degR == 11'sd180) || (degL == -11'sd180))
					next_state = s2;
				else
					next_state = s8;
			end
		endcase
	end
endmodule
