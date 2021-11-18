// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// roomba_modules.v

//This file contains all instantiated modules for bumpstop_top.v


//-------------------------------------------------------------------------------------------
// this is a generic module that outputs a pwm signal at 1kHz
// this means that the PWM period is 1ms (16000 cycles)
// the module takes a 16MHz clock
// an enable input that serves as a active low reset
// timeon is a value form 0 to 16000 that determines the duty cyle of the signal
// PWM is the output
module pwm (
	input wire clk,
	input enable,
	input[15:0] timeon,
	output reg PWM
	);
	
// Register Declaration
	reg [15:0] timerPWM;
	
// Datapath clocked
	always @(posedge clk)
	begin
		if (enable)
		begin
			timerPWM <= timerPWM + 1'b1;
			if (timerPWM == 16'd16000)
			begin
				timerPWM <= 0;
				PWM <= 1'b1;
			end
			
			else if (timerPWM > timeon)
				PWM <= 1'b0;
		end
		
		else
		begin
			timerPWM <=0;
			PWM <= 0;
		end
	end
endmodule


//------------------------------------------------------------------------------------
// We need to develop a slower clock to sample the encoder appropriately
// the WebFPGA contains a 16MHz clock which is so fast that it might
// see a single posedge from the encoder pulse in various clock cycles.
// this module develops a new clock from the WebFPGA's 16MHz clock
module newclock (
	input clk, enable,
	input [15:0] divider,
	output reg newclk
	);
	
// Register Declaration
	reg [16:0] counter;
	
//Datapath
	
	always @(posedge clk)
	begin
		if (enable)
		begin
			counter <= counter + 1;
			
			if (counter == divider)
			begin
				counter <= 0;
				newclk <= ~newclk;
			end	
		end
		
		else
		begin
			newclk <= 0;
			counter <= 0;
		end
		
	
	end
endmodule



//----------------------------------------------------------------------------------------------
// This module takes motor direction, status, encoder input, and an enable bit to calculate the
// current rotation and degree position the wheel is in
module encoder (
	input clk, motor_dir, motor_en, encoder_en, encoder_pulse,
	output reg signed [10:0] rev, deg
	);
	
// Register Declaration
	reg signed [10:0] old_deg, old_rev;
	//degree overflow signal
	wire ov_deg;

// Datapath
	
	always @(posedge clk)
	begin
		if (encoder_en && !ov_deg)
			deg <= old_deg;
			
		else if (encoder_en && ov_deg)
		begin
			rev = old_rev;
			deg = 11'sd0;
		end
		
		else
		begin
			deg <= 11'sd0;
			rev <= 11'sd0;
		end
	end
	
	
	
	always @(posedge encoder_pulse)
	begin
		if (motor_dir)
		begin
			old_deg <= deg - 11'sd1;
		end
		
		else
		begin
			old_deg <= deg + 11'sd1;
		end
		
	end
	
	assign ov_deg = (deg >= 11'sd360) || (deg <= -11'sd360);
	
	always @(*) begin
		if (motor_dir)
			old_rev <= rev - 11'sd1;
		else 
			old_rev <= rev + 11'sd1;
	end
endmodule
