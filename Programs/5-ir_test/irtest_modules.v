// Eric Schwarz Iglesias
// ECE 484/485 Senior Design
// Team 4: FPGA for Robotics Education
// irtest_modules.v

//This file contains all instantiated modules for irtest_top.v


module IRcontrol (
	input wire clk,
	input wire [7:0] channel_sel,
	
	inout wire ir_snsrch0, ir_snsrch1, ir_snsrch2, ir_snsrch3,
			ir_snsrch4, ir_snsrch5, ir_snsrch6, ir_snsrch7,
	output wire[16:0] ttd0, ttd1, ttd2, ttd3, ttd4, ttd5, ttd6, ttd7,
	output wire ir_evenLED, ir_oddLED
	);
	
// Register and Wire Declaration	
	wire ir_evenLED_en, ir_oddLED_en;
	
// Module Instantiations
	// the enable input in the pwm modules for the ir LEDs can be determined by what
	// channels are selected, if only even cannels are selected, we only need to 
	// enable the even LED control. The same applies for odd channels.
	
	
	pwm irevenLED (clk, ir_evenLED_en, 16'd16000, ir_evenLED);
	pwm iroddLED (clk, ir_oddLED_en, 16'd16000, ir_oddLED);
	
	IRread ch0 (clk, channel_sel[0], ir_snsrch0, ttd0);
	IRread ch1 (clk, channel_sel[1], ir_snsrch1, ttd1);
	IRread ch2 (clk, channel_sel[2], ir_snsrch2, ttd2);
	IRread ch3 (clk, channel_sel[3], ir_snsrch3, ttd3);
	IRread ch4 (clk, channel_sel[4], ir_snsrch4, ttd4);
	IRread ch5 (clk, channel_sel[5], ir_snsrch5, ttd5);
	IRread ch6 (clk, channel_sel[6], ir_snsrch6, ttd6);
	IRread ch7 (clk, channel_sel[7], ir_snsrch7, ttd7);
	

// Datapath
	assign ir_evenLED_en = channel_sel[0] | channel_sel[2] | channel_sel[4] | channel_sel[6];
	assign ir_oddLED_en = channel_sel[1] | channel_sel[3] | channel_sel[5] | channel_sel[7];
	
endmodule


//-----------------------------------------------------------------------------------
// This module reads the ttd(time to decay) for a single QTRX channel
module IRread (
	input clk, enable,
	inout sensor,
	output reg[16:0] ttd
	);
// Parameters
	localparam s0	= 3'b000;
	localparam s1	= 3'b001;
	localparam s2	= 3'b010;
	localparam s3	= 3'b011;
	localparam s4	= 3'b100;
	localparam s5	= 3'b101;
	
// Register and Wire declaration
	reg[2:0] current_state, next_state;
	reg timer10us_en, timerttd_en, drive_sensor, writettd;
	wire[7:0] timer10us;
	wire[16:0] timerttd;

// Module Instantiations
	timer ten_us_buffer 	(clk, timer10us_en, 1'bZ, timer10us);
	timer decay_timer	(clk, timerttd_en, 1'bZ, timerttd);

// State Machine
	always @(posedge clk)
	begin
		if (enable)
			current_state <= next_state;
		else
			current_state <= 0;
	end
	
	always @(*)
	begin
		casex(current_state)
			//reset state
			s0: begin
				drive_sensor 	= 0;
				timer10us_en	= 0;
				timerttd_en 	= 0;
				writettd	= 0;
				
				next_state = s1;
			end
			
			// drive the sensor high and wait at least 10us
			s1: begin
				drive_sensor 	= 1;
				timer10us_en	= 1;
				timerttd_en 	= 0;
				writettd	= 0;
				
				if (timer10us == 8'd160)
					next_state = s2;
				else
					next_state = s1;
			end
			
			//now the sensor is switched to an input and the ttd timer starts
			s2: begin
				drive_sensor 	= 0;
				timer10us_en	= 0;
				timerttd_en 	= 1;
				writettd	= 0;
				
				if (sensor == 0)
					next_state = s3;
				else
					next_state = s2;
			end
			
			//write the current value in the ttd timer to the ttd output
			//then begin the entire process again
			s3: begin
				drive_sensor 	= 0;
				timer10us_en	= 0;
				timerttd_en 	= 1;
				writettd	= 1;
				
				next_state = s1;
			end
		endcase
	end
	
// Datapath
	
	assign sensor = drive_sensor ? 1'b1 : 1'bZ;
	
	always @(*)
	begin
		if (!enable)
		begin
			ttd = 0;
		end
		else if (writettd)
			ttd = timerttd;
		else
			ttd = ttd;
	end
	
endmodule


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
// This module is a simple counter that can count up to a second
// enable serves as an active low reset and stop holds the value of the timer
// this counter runs at clock speed which is 16MHz if connected to WF_CLK,
// that means that the counter increments every 62.5ns
module timer (
	input clk, enable, stop,
	output reg[23:0] counter
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
