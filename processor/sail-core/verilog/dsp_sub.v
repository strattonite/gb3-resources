module dsp_sub(a_in, b_in, sub);
    input [31:0] a_in;
    input [31:0] b_in;
    output [31:0] sub;

    SB_MAC16 i_sbmac16_sub(
        .A(a_in[31:16]),
        .B(a_in[15:0]),
        .C(~b_in[31:16]), 
        .D(~b_in[15:0]),
        .O(sub),
        .CLK(), //clock
        .CE(1'b0), // clock enable
        .IRSTTOP(1'b0), //don't reset top
        .IRSTBOT(1'b0), //don't reset bottom
        .ORSTTOP(1'b0), //don't reset top accumulator
        .ORSTBOT(1'b0), //don't reset bottom accumulator
        .AHOLD(1'b0), //load A
        .BHOLD(1'b0), //load B
        .CHOLD(1'b0), //load C
        .DHOLD(1'b0), //load D
        .OHOLDTOP(1'b0), //load top output
        .OHOLDBOT(1'b0), //load bottom output
        .OLOADTOP(1'b0), //load top output
        .OLOADBOT(1'b0), //load bottom output
        .ADDSUBTOP(1'b0), //1 for sub
        .ADDSUBBOT(1'b0), //1 for sub
        .CO(), //carry out
        .CI(1'b0), //no carry in
        //MAC cascading ports.
        .ACCUMCI(1'b0),//no carry in
        .ACCUMCO(),
        .SIGNEXTIN(1'b0),
        .SIGNEXTOUT()
    );

// mult_8x8_all_pipelined_unsigned [24:0] = 001_0000010_0000010_0111_0110
// Read configuration settings [24:0] from left to right while filling the instance parameters.
defparam i_sbmac16_sub.B_SIGNED = 1'b0;
defparam i_sbmac16_sub.A_SIGNED = 1'b0;
defparam i_sbmac16_sub.MODE_8x8 = 1'b1; //1 for low power multiply disable
defparam i_sbmac16_sub.BOTADDSUB_CARRYSELECT = 2'b01; //01 for 1 carry in for 2's complement
defparam i_sbmac16_sub.BOTADDSUB_UPPERINPUT = 1'b1;// 1 for input from register D
defparam i_sbmac16_sub.BOTADDSUB_LOWERINPUT = 2'b00;//00 for input from register B
defparam i_sbmac16_sub.BOTOUTPUT_SELECT = 2'b00; //00 for output from lower add/sub
defparam i_sbmac16_sub.TOPADDSUB_CARRYSELECT = 2'b10;// 10 for cascade with lower adder
defparam i_sbmac16_sub.TOPADDSUB_UPPERINPUT = 1'b1; // 1 for input from register
defparam i_sbmac16_sub.TOPADDSUB_LOWERINPUT = 2'b00; //00 for input from registers
defparam i_sbmac16_sub.TOPOUTPUT_SELECT = 2'b00; //00 for add/subtract
defparam i_sbmac16_sub.PIPELINE_16x16_MULT_REG2 = 1'b0; //0 for low power as not using 16x16 multiply
defparam i_sbmac16_sub.PIPELINE_16x16_MULT_REG1 = 1'b0; //same as above
defparam i_sbmac16_sub.BOT_8x8_MULT_REG = 1'b0 ; //0 as not using multiply
defparam i_sbmac16_sub.TOP_8x8_MULT_REG = 1'b0 ;//0 as not using multiply
defparam i_sbmac16_sub.D_REG = 1'b0 ;
defparam i_sbmac16_sub.B_REG = 1'b0 ;
defparam i_sbmac16_sub.A_REG = 1'b0 ;
defparam i_sbmac16_sub.C_REG = 1'b0 ;
defparam i_sbmac16_sub.NEG_TRIGGER = 1'b0;    
endmodule