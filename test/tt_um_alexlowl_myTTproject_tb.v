/*
	Testbench for tt_um_alexlowl_myTTproject.
*/

`timescale 1ns / 1ns // `timescale <time_unit> / <time_precision>

//`include "../src/tt_um_alexlowl_myTTproject.v"

module tt_um_alexlowl_myTTproject_tb;

	// inputs for tt_um_alexlowl_myTTproject
	reg [7:0] ui_in = 8'h00;				// set inputs tp 0
	reg [7:0] uio_in = 8'h00;				// set bidirectional inputs to 0
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
	always #5 clk = ~clk; // wait 5 time units (e.g. 5ns)
	/* verilator lint_on STMTDLY */
	
	initial begin
		$dumpfile("tt_um_alexlowl_myTTproject_tb.vcd");
		$dumpvars;
	
		/* verilator lint_off STMTDLY */
		#50 rst_n = 1'b1; // deassert reset
		#50 ui_in[0] = 1'b1;
		#50 ui_in[0] = 1'b0;
		#50 ui_in[0] = 1'b1;
		#50 ui_in[0] = 1'b0;
		#3000 $finish; // finish
		/* verilator lint_on STMTDLY */
	end
endmodule // tt_um_alexlowl_myTTproject_tb
