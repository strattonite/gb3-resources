module pll (
    // f_pllin = 27 MHz
    // f_pllout = f_pllin * (DIVF+1) / (2^DIVQ *(DIVR+1))
    input  clock_in,
    output clock_out,
    output locked
);

SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'b0011), 
    .DIVF(7'b00000), 
    .DIVQ(3'b100), 
) uut (
    .LOCK(locked),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clock_in),
    .PLLOUTCORE(clock_out)
);

endmodule