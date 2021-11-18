// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// roomba_top.v

// This Verilog file is to be synthesized and flashed into a WebFPGA Shasta Board
// interfaced to a TI-RSLK-MAX chassis board.
// This specific design allows you to test the values of the IR sensors by saving
// two values (in this case they are meant to be black and white) then you can move
// the robot around and the LEDs on the RSLK will reflect if the value that the
// sensor is looking at is more or less than what you saved


module fpga_top (
	input wire WF_CLK, WF_BUTTON,
	input bump0, bump1, bump2, bump3, bump4, bump5,
	input wire motorL_encdr, motorR_encdr,
	inout wire ir_snsrch0, ir_snsrch1, ir_snsrch2, ir_snsrch3,
			ir_snsrch4, ir_snsrch5, ir_snsrch6, ir_snsrch7,	
	output wire ir_evenLED, ir_oddLED,
	output reg ledFR, ledFL, ledBR, ledBL,
	output wire motorL_pwm, motorR_pwm,
	output wire motorL_en, motorL_dir, motorR_en, motorR_dir
	);
	
	assign motorL_en = 0;
	assign motorR_en = 0;
	
	assign motorL_pwm = 0;
	assign motorR_pwm = 0;
	
// Parameters
	localparam s0	= 3'b000;
	localparam s1	= 3'b001;
	localparam s2	= 3'b010;
	localparam s3	= 3'b011;
	localparam s4	= 3'b100;
	localparam s5	= 3'b101;
	
// Register and Wire declaration
	reg[2:0] next_state, current_state = s0;
	reg ir_compare_en, save_white, save_black;
	
	reg[7:0] channel_sel;
	wire[16:0] ttd0, ttd1, ttd2, ttd3, ttd4, ttd5, ttd6, ttd7;
	reg[16:0] white_thresh, black_thresh;
	
// Module instantiations

	IRcontrol QRTX8ch (
		WF_CLK, channel_sel, 
		ir_snsrch0, ir_snsrch1, ir_snsrch2, ir_snsrch3,
		ir_snsrch4, ir_snsrch5, ir_snsrch6, ir_snsrch7,
		ttd0, ttd1, ttd2, ttd3, ttd4, ttd5, ttd6, ttd7,
		ir_evenLED, ir_oddLED
		);

// State Machine

	always @(posedge WF_CLK)
		current_state <= next_state;

		
	always @(*)
	begin
		casex(current_state)
			//reset state
			s0: begin
				channel_sel	= 8'b00000000;
				ir_compare_en	= 1'b0;
				save_white	= 1'b0;
				save_black	= 1'b0;
				
				ledFR		= 1'b0;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				next_state = s1;
			end
			
			//callibrate white
			s1: begin
				channel_sel	= 8'b00000001;
				ir_compare_en	= 1'b0;
				save_white	= 1'b1;
				save_black	= 1'b0;
				
				ledFR		= 1'b1;
				ledFL		= 1'b0;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!bump0)
					next_state = s2;
				else
					next_state = s1;
			end
			
			//callibrate black
			s2: begin
				channel_sel	= 8'b10000000;
				ir_compare_en	= 1'b0;
				save_white	= 1'b0;
				save_black	= 1'b1;
				
				ledFR		= 1'b0;
				ledFL		= 1'b1;
				ledBR		= 1'b0;
				ledBL		= 1'b0;
				
				if (!bump5)
					next_state = s3;
				else
					next_state = s2;
			end
			
			// now compare
			s3: begin
				channel_sel	= 8'b10000001;
				ir_compare_en	= 1'b1;
				save_white	= 1'b0;
				save_black	= 1'b0;
				
				ledFR		= 1'bZ;
				ledFL		= 1'bZ;
				ledBR		= 1'bZ;
				ledBL		= 1'bZ;
				
				next_state = s3;
			end
		endcase
	end
	


// Datapath

	always @(*) begin
		if (ir_compare_en)
		begin
			if (ttd0 > white_thresh)
			begin
				ledBR = 1'b0;
				ledFR = 1'b1;
			end
			
			else
			begin
				ledBR = 1'b1;
				ledFR = 1'b0;
			end
			
			
			if (ttd7 > black_thresh)
			begin
				ledBL = 1'b0;
				ledFL = 1'b1;
			end
			
			else
			begin
				ledBL = 1'b1;
				ledFL = 1'b0;
			end
		end
		
		else
		begin
			ledFR = 1'bZ;
			ledFL = 1'bZ;
			ledBR = 1'bZ;
			ledBL = 1'bZ;
		
		end
	end
	
	always @(*)
	begin
		if (save_white)
			white_thresh = ttd0;
		else
			white_thresh = white_thresh;
			
		if (save_black)
			black_thresh = ttd7;
		else
			black_thresh = black_thresh;	
	end
	
endmodule
