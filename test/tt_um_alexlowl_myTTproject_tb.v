/*
	Testbench for tt_um_alexlowl_myTTproject.
*/

`timescale 1ns / 1ns // `timescale <time_unit> / <time_precision>

//`include "../src/tt_um_alexlowl_myTTproject.v"

module tt_um_alexlowl_myTTproject_tb;

	// inputs for tt_um_alexlowl_myTTproject
	reg [7:0] ui_in = 8'h0;					// set inputs tp 0
	reg [7:0] uio_in = 8'h0;				// set bidirectional inputs to 0
	reg ena = 1'b1;							// enable
	reg clk = 1'b0;							// clock initially low
	reg rst_n = 1'b0;  						// Active low reset
	
	// outputs from tt_um_alexlowl_myTTproject
	wire [7:0] 	uo_out;
	wire [7:0] 	uio_out;
	wire [7:0] 	uio_oe;
	
	// DUT
	tt_um_alexlowl_myTTproject tt_um_alexlowl_myTTproject_dut (
		.ui_in(ui_in),
		.uo_out(uo_out),
		.uio_in(uio_in),
		.uio_out(uio_out),
		.uio_oe(uio_oe),
		.ena(ena),
		.clk(clk),
		.rst_n(rst_n)
	);
				
	// Press a button in a realistic way (incl. bouncing)
    task press_bouncy_button(input integer btn);
    begin
    	ui_in[btn] = 1'b1;					// bounce 1ms
        #(1000000);     					
        ui_in[btn] = 1'b0;
        #(1000000);
        ui_in[btn] = 1'b1;					// bounce 1ms
        #(1000000);     	
        ui_in[btn] = 1'b0;
        #(1000000);
        ui_in[btn] = 1'b1;					// valid button press
        #(10000000);     					// btn released after 10ms
        ui_in[btn] = 1'b0;
    end
    endtask			
				
	// Generate clock
	/* verilator lint_off STMTDLY */
	always #10 clk = ~clk; 					// wait 10ns -> 50MHz (T=20ns)
	/* verilator lint_on STMTDLY */
	
	initial begin
		$dumpfile("tt_um_alexlowl_myTTproject_tb.vcd");
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.rst_n);
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.ui_in);
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.uo_out);
		//$dumpvars(1, tt_um_alexlowl_myTTproject_tb.tt_um_alexlowl_myTTproject_dut);		// for "faster" simulation (still takes decades...)

	/* verilator lint_off STMTDLY */
		
		/*
		// Fast simulation
		#10000000 rst_n = 1'b1; 				// deassert reset
		#10000000 ui_in[0] = 1'b1;				// pause_btn pressed -> go
		#10000000 ui_in[0] = 1'b0;				// pause_btn released after 10ms
		#10000000 ui_in[1] = 1'b1;				// slower
		#10000000 ui_in[1] = 1'b0;
		#10000000 ui_in[2] = 1'b1;				// faster
		#10000000 ui_in[2] = 1'b0;
		#100000000 ui_in[0] = 1'b1;				// after 100ms pause_btn pressed again -> pause
		#10000000 ui_in[0] = 1'b0;				// pause_btn released after 10ms			
		#10000000 $finish; // finish
		*/
		
		// Detailed simulation incl debouncing demo (fun fact: calculating for min)
		#10000000
		rst_n = 1'b1; 							// deassert reset
		#10000000
		press_bouncy_button(0);					// pause_btn pressed -> go
		#400000000 
		press_bouncy_button(1);					// after 400ms slower
		#400000000 
		press_bouncy_button(2);					// after 400ms faster
		#600000000 
		press_bouncy_button(0);					// after 600ms pause_btn pressed again -> pause			
		#200000000 
		$finish; // finish						// after 200ms --> end
		
	/* verilator lint_on STMTDLY */	
	end
endmodule // tt_um_alexlowl_myTTproject_tb
