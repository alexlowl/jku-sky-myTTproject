/*
	Testbench for tt_um_alexlowl_myTTproject.
*/

`timescale 1ns / 1ns // `timescale <time_unit> / <time_precision>

//`include "../src/tt_um_alexlowl_myTTproject.v"

module tt_um_alexlowl_myTTproject_tb;

	// inputs for tt_um_alexlowl_myTTproject
	reg [7:0] ui_in = 8'h0;				// set inputs tp 0
	reg [7:0] uio_in = 8'h0;				// set bidirectional inputs to 0
	reg ena = 1'b1;						// enable
	reg clk = 1'b0;						// clock initially low
	reg rst_n = 1'b0;  					// Active low reset
	
	// outputs from tt_um_alexlowl_myTTproject
	wire [7:0] 	uo_out;
	wire [7:0] 	uio_out;
	wire [7:0] 	uio_oe;
	
	//DUT
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
				
	//Generate clock
	/* verilator lint_off STMTDLY */
	always #10 clk = ~clk; // wait 10 time units (e.g. 10ns) -> 50MHz
	/* verilator lint_on STMTDLY */
	
	initial begin
		$dumpfile("tt_um_alexlowl_myTTproject_tb.vcd");
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.rst_n);
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.ui_in);
		$dumpvars(0, tt_um_alexlowl_myTTproject_tb.uo_out);
		//$dumpvars(1, tt_um_alexlowl_myTTproject_tb.tt_um_alexlowl_myTTproject_dut);

	
		/* verilator lint_off STMTDLY */
		
		
		// Fast simulation
		#300 rst_n = 1'b1; 					// deassert reset
		#300 ui_in[0] = 1'b1;				// pause_btn pressed -> go
		#300 ui_in[0] = 1'b0;				// pause_btn released
		#300 ui_in[1] = 1'b1;				// faster
		#300 ui_in[1] = 1'b0;
		#300 ui_in[2] = 1'b1;				// slower
		#300 ui_in[2] = 1'b0;
		#100000000 ui_in[0] = 1'b1;			// after 0.09sec -> pause_btn pressed again -> pause
		#300 ui_in[0] = 1'b0;				// pause_btn released				
		#300 $finish; // finish
		
		/*
		// Detailed simulation
		#300 rst_n = 1'b1; 					// deassert reset
		#50000000 ui_in[0] = 1'b1;			// after 0.05sec pause_btn pressed -> go
		#300 ui_in[0] = 1'b0;				// pause_btn released
		#2000000000 ui_in[1] = 1'b1;		// after 2sec -> faster
		#300 ui_in[1] = 1'b0;
		#2000000000 ui_in[2] = 1'b1;		// after 2sec -> slower
		#300 ui_in[2] = 1'b0;
		#2000000000 ui_in[0] = 1'b1;		// after 2sec pause_btn pressed -> pause
		#300 ui_in[0] = 1'b0;				// pause_btn released				
		#300 $finish; // finish
		*/
		
	/* verilator lint_on STMTDLY */	
	end
endmodule // tt_um_alexlowl_myTTproject_tb
