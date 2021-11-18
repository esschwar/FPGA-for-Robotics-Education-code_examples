// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// linefollow_top.v


// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This design makes use of all the subsystems in the TI-RSLK-MAX
// chassis board to find a black line and begin to follow it. If
// any of the bumper switches are pressed, the car will stop and
// wait for a button press to start again

module fpga_top (
	input wire WF_CLK, WF_BUTTON,
	input bump0, bump1, bump2, bump3, bump4, bump5,
	input wire motorL_encdr, motorR_encdr,
	inout wire ir_snsrch0, ir_snsrch1, ir_snsrch2, ir_snsrch3,
			ir_snsrch4, ir_snsrch5, ir_snsrch6, ir_snsrch7,	
	output wire ir_evenLED, ir_oddLED,
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
	localparam SPEED50	= 16'd8000;
	localparam SPEED20	= 16'd3200;
	localparam SPEED10	= 16'd1600;
	localparam SPEED05	= 16'd800;
	
// Register and Wire declaration
	reg[3:0] next_state, current_state = s0;
	
	reg[7:0] channel_sel;
	wire[16:0] ttd0, ttd1, ttd2, ttd3, ttd4, ttd5, ttd6, ttd7;
	reg[16:0] black_thresh;
	reg save_black, save_line_view, halfms_en;
	wire [10:0] timer_halfms;
	wire[7:0] line_view;
	wire[7:0] i_line_view;
	reg save_line_view;
	
	reg motorL_drive, motorR_drive, encoder_en;
	
	reg[15:0] motorR_speed, motorL_speed;
	
	wire signed [10:0] revL, degL, revR, degR;
	wire slowclk;
	
// Module Instantiations

// IR instantiation
	IRcontrol QRTX8ch (
		WF_CLK, channel_sel, 
		ir_snsrch0, ir_snsrch1, ir_snsrch2, ir_snsrch3,
		ir_snsrch4, ir_snsrch5, ir_snsrch6, ir_snsrch7,
		ttd0, ttd1, ttd2, ttd3, ttd4, ttd5, ttd6, ttd7,
		ir_evenLED, ir_oddLED
		);
	
	// motor instantiations	
	pwm motorL (WF_CLK, motorL_drive, motorL_speed, motorL_pwm);
	pwm motorR (WF_CLK, motorR_drive, motorR_speed, motorR_pwm);
	
	//2khz clock
	newclock twohzclk(WF_CLK, 1, 16'd8000, slowclk);
	
	//encoder instantiations
	encoder Rwheel (slowclk, motorR_dir, motorR_drive, encoder_en, motorR_encdr, revR, degR);
	encoder Lwheel (slowclk, motorL_dir, motorL_drive, encoder_en, motorL_encdr, revL, degL);
	
	//timer that increments every .5ms
	timer halfms (slowclk, halfms_en, 1'bZ, timer_halfms);
	
// Always Block
	always @(posedge WF_CLK)
		current_state <= next_state;
		
// State Machine

	always @(*)
	begin
		casex(current_state)
			// reset state
			s0: begin
				motorL_en	= 1'b0;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b0;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b00000000;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				next_state = s1;
			end
			
			// Callibrate Black
			s1: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b1;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b1;
				ledBL		= 1'b1;
				
				if (!bump2)
					next_state = s2;
				else
					next_state = s1;
			end
			
			// wait for start input
			s2: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!WF_BUTTON)
					next_state = s3;
				else
					next_state = s2;
			end
			
			// move forward and find the black line with the middle two sensors
			s3: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b00011000;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				// here we can simply look for more than 0 since bits
				// 3 and 4 are the only ones that will change
				if (line_view > 8'b00000000)
					next_state = s4;
				else
					next_state = s3;
			end
			
			// spin counter clockwise for a half turn
			s4: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b1;
				motorL_drive	= 1'b1;
				motorL_speed	= SPEED10;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b1;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b1;
				
				if ((degL == -11'sd90) || (degR == 11'sd359))
					next_state = s5;
				else
					next_state = s4;
			end
			
			// wait 1 second and capture what the sensors see
			s5: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b0;
				motorL_speed	= SPEED10;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b0;
				motorR_speed	= SPEED10;
				
				encoder_en	= 1'b1;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b1;
				halfms_en   	= 1'b1;
					
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b1;
				ledBL		= 1'b1;
				
				if (timer_halfms == 11'd2000)
				    next_state = s6;
				else
				    next_state = s5;
			end
			
			
			// move forward and keep sight of the line
			s6: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!bump0 || !bump1 || !bump2 || !bump3 || !bump4 || !bump5)
					next_state = s2;
				else if ((line_view == i_line_view << 1) || (line_view == i_line_view << 2))
					next_state = s7;
				else if ((line_view == i_line_view >> 1) || (line_view == i_line_view >> 2))
					next_state = s8;
				else
					next_state = s6;
			end
			
			// move towards the left
			s7: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				motorL_speed	= SPEED10;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				motorR_speed	= SPEED20;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b1;
				
				if (!bump0 || !bump1 || !bump2 || !bump3 || !bump4 || !bump5)
					next_state = s2;
				else if (line_view == i_line_view)
					next_state = s6;
				else
					next_state = s7;
			end
			
			// move towards the right
			s8: begin
				motorL_en	= 1'b1;
				motorL_dir	= 1'b0;
				motorL_drive	= 1'b1;
				motorL_speed	= SPEED20;
				
				motorR_en	= 1'b1;
				motorR_dir	= 1'b0;
				motorR_drive	= 1'b1;
				motorR_speed	= SPEED10;
				
				encoder_en	= 1'b0;
				
				channel_sel	= 8'b11111111;
				save_black	= 1'b0;
				save_line_view  = 1'b0;
				halfms_en   	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b1;
				ledBL		= 1'b0;
				
				if (!bump0 || !bump1 || !bump2 || !bump3 || !bump4 || !bump5)
					next_state = s2;
				else if (line_view == i_line_view)
					next_state = s6;
				else
					next_state = s8;
			end
		endcase
	end
	
// Datapath
	// To callibrate the black threshhold we need to look at the
	// largest value from all the sensors since we don't know which 
	// sensor is exactly on top of the black line
	
	always @(*)
	begin
		if (save_black)
		begin
			black_thresh = 17'd0;
			if (black_thresh < ttd0)
				black_thresh = ttd0;
			if (black_thresh < ttd1)
				black_thresh = ttd1;
			if (black_thresh < ttd2)
				black_thresh = ttd2;
			if (black_thresh < ttd3)
				black_thresh = ttd3;
			if (black_thresh < ttd4)
				black_thresh = ttd4;
			if (black_thresh < ttd5)
				black_thresh = ttd5;
			if (black_thresh < ttd6)
				black_thresh = ttd6;
			if (black_thresh < ttd7)
				black_thresh = ttd7;
			else
				black_thresh = black_thresh;
		end
		else
			black_thresh = black_thresh;
	end
	
	
	
	
	assign i_line_view = save_line_view ? line_view : i_line_view;
	
	// subtracting the threshold by something allows us a buffer for sensitivity
	assign line_view[0] = ttd0 >= (black_thresh - 17'd10);
	assign line_view[1] = ttd1 >= (black_thresh - 17'd10);
	assign line_view[2] = ttd2 >= (black_thresh - 17'd10);
	assign line_view[3] = ttd3 >= (black_thresh - 17'd10);
	assign line_view[4] = ttd4 >= (black_thresh - 17'd10);
	assign line_view[5] = ttd5 >= (black_thresh - 17'd10);
	assign line_view[6] = ttd6 >= (black_thresh - 17'd10);
	assign line_view[7] = ttd7 >= (black_thresh - 17'd10);
	
endmodule
