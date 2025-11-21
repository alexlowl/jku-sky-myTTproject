/*
 * Copyright (c) 2024 alexlowl
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alexlowl_myTTproject (
    input  wire [7:0] ui_in,					// ui_in[0] = pause/run, ui_in[1] = slower, ui_in[2] = faster
    output wire [7:0] uo_out,					// LED-Bargraph
    input  wire [7:0] uio_in,   				// unused
    output wire [7:0] uio_out,  				// unused
    output wire [7:0] uio_oe,   				// IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,     					// always 1 when the design is powered, so you can ignore it
    input  wire       clk,      				// clock
    input  wire       rst_n     				// reset_n - low to reset
);

    // Input
    wire pause_btn = ui_in[0];
    wire slower  = ui_in[1];
    wire faster  = ui_in[2];
    
    // Output
    reg [7:0] led_out;
    assign uo_out = led_out;
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Parameter
    localparam PWM_BITS     = 8;   				// 8-bit counter for PWM
    localparam DIVIDER_BITS = 35;  				// 35-bit counter for movement speed

    // Register
    reg [PWM_BITS-1:0] pwm_counter;				// 8 bit
    reg [DIVIDER_BITS-1:0] slow_counter;		// 35 bit
    reg [2:0] pos;								// 3 bit for position (8 LEDs)
    reg dir;									// 1 bit, 0 = direction 1 (count up), 1 = direction 2 (count down)

    reg [2:0] speed_level; 						// 3 bit decimal, 0 = slowest, 7 = fastetst
    reg faster_prev;							// 1 bit flag for edge detection
    reg slower_prev;							// 1 bit flag for edge detection

	reg pause_prev;     						// previous pause button state
    reg paused;         						// 1 = paused, 0 = running
    reg started;        						// becomes 1 @ first unpause after power up -> for initial restart behavior

    // Just for the simulation
	`ifndef SYNTHESIS
	initial begin
		slow_counter = 0;
		pos = 0;
		dir = 0;
		paused = 1;
		started = 0;
	end
	`endif

    // Debouncing of input buttons
    localparam integer DEBOUNCE_BITS = 18;  	// debounce time window 2^18 clock cycles

    reg [DEBOUNCE_BITS-1:0] db_counter_pause;
    reg [DEBOUNCE_BITS-1:0] db_counter_faster;
    reg [DEBOUNCE_BITS-1:0] db_counter_slower;

    reg pause_stable;
    reg faster_stable;
    reg slower_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            db_counter_pause  <= 0;
            db_counter_faster <= 0;
            db_counter_slower <= 0;
            pause_stable      <= 0;
            faster_stable     <= 0;
            slower_stable     <= 0;
        end 
        else begin
            if (pause_btn == pause_stable)							// debounce pause button
                db_counter_pause <= 0;  							// reset counter
            else begin
                db_counter_pause <= db_counter_pause + 1;
                if (&db_counter_pause)  							// overflow -> input was stable long enough
                    pause_stable <= pause_btn;
            end

            if (faster == faster_stable)							// debounce faster button
                db_counter_faster <= 0;
            else begin
                db_counter_faster <= db_counter_faster + 1;
                if (&db_counter_faster)
                    faster_stable <= faster;
            end

            if (slower == slower_stable)							// debounce slower button
                db_counter_slower <= 0;
            else begin
                db_counter_slower <= db_counter_slower + 1;
                if (&db_counter_slower)
                    slower_stable <= slower;
            end
        end
    end

    // Edge detection for slower/faster buttons (positive edge)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin											// CAVE: active low -> !rst_n -> rst_n is not 1 -> is 0 -> reset active
            speed_level <= 3'd3;
            faster_prev <= 0;
            slower_prev <= 0;
        end 
        else begin
            if (faster_stable && !faster_prev && speed_level < 7)	// prevent overflow
                speed_level <= speed_level + 1; 					// faster
            if (slower_stable && !slower_prev && speed_level > 0)	// prevent underflow
                speed_level <= speed_level - 1; 					// slower

            faster_prev <= faster_stable;
            slower_prev <= slower_stable;
        end
    end

    // Edge detection for pause button (positive edge) + FF
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pause_prev <= 0;
            paused     <= 1;
            started    <= 0;
        end 
        else begin
            pause_prev <= pause_stable;

            if (pause_stable && !pause_prev) begin
                paused <= ~paused;

                if (paused == 1'b1 && started == 1'b0) begin		// first unpause after power up -> set started-flag
                    started <= 1'b1;
                end
            end
        end
    end

    // Clock divider for movement speed (scale down clock)
    wire slow_tick = (slow_counter == 0);							// if slow_counter == 0: slow_tick = 1

    wire [34:0] divider_step = (35'd1 << (speed_level + 10));		// 1<<n -> 2^n -> devider_step = 2^(speed_level + 10)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slow_counter <= 0;
        else
            slow_counter <= slow_counter + divider_step;			// 35-bit counter -> @ overflow -> 0 -> trigger slow_tick
    end
    
    // PWM counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;							// 8-bit counter
    end
    
    // Movement of light
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos <= 0;
            dir <= 0;
        end 
        else if (slow_tick && !paused) begin				// position update @ slow_tick & not paused
		    if (!started) begin								// first unpause after power up
		        pos <= 0;
		        dir <= 0;
		    end
		    else begin
            	if (dir == 0) begin								// dir = 0 -> direction 1 (count up)
                	if (pos == 7) begin							// upper limit
                  	  	dir <= 1;								// change direction -> dir = 1 -> direction 2 (count down)
                   		pos <= pos - 1;							// then count down
                	end 
                	else begin
                    	pos <= pos + 1;							// count up (for dir = 0)
                	end
            	end 
            	else begin										// dir = 1 -> direction 2 (count down)
                	if (pos == 0) begin							// lower limit
                   		dir <= 0;								// change direction -> dir = 0 -> direction 1 (count up)
                    	pos <= pos + 1;							// then count up
                	end 
                	else begin
                    	pos <= pos - 1;							// count down (for dir = 1)
                	end
                end
            end
        end
    end
    

    // LED brightness at a certain position
    reg [7:0] brightness [7:0];
    integer i;

    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            if (i[2:0] == pos)																// current LED
                brightness[i] = 8'd255;      												// max brightness
            else if ((i[2:0] == pos + 1 && pos != 7) || (i[2:0] == pos - 1 && pos != 0))	// neighboring LEDs
                brightness[i] = 8'd100;      												// medium brightness
            else																			// all other LEDs
                brightness[i] = 8'd0;        												// off
        end
    end


    // PWM output to LEDs
    always @(*) begin
        for (i = 0; i < 8; i = i + 1)														// LED position
            led_out[i] = (pwm_counter < brightness[i]) ? 1'b1 : 1'b0;					// LED on for the HIGH period of the PWM duty cycle
    end

    // List all unused inputs to prevent warnings
  	wire _unused = &{ena, uio_in, ui_in[7:1], 1'b0};

endmodule
