module pll #(
	// I will implement the slowest clock possible, f_pllout = 5860 Hz
	// f_pllin = 12 MHz
	// f_pllout = f_pllin * (DIVF+1) / (2^DIVQ *(DIVR+1))

    parameter DIVR    =  4'b1111, // DIVR = 15
    parameter DIVF    = 7'b0000000, // DIVF = 0
    parameter DIVQ    =  3'b111, // DIVQ = 7
    parameter FLT_RNG =  3'b001. // FILTER_RANGE = 1
	
    input  clock_in,
	output clock_out,
	output locked
	);

SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(DIVR),        // DIVR =  0
		.DIVF(DIVF),        // DIVF = 66
		.DIVQ(DIVQ),        // DIVQ =  3
		.FILTER_RANGE(FLT_RNG) // FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.PACKAGEPIN(clock_in),
		.PLLOUTCORE(clock_out)
		);

endmodule