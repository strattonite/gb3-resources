module dsp_adder_subtractor(a_in, b_in, sum, sub, clk);
    input [31:0] a_in;
    input [31:0] b_in;
    input clk; //cynchronous clock
    output [31:0] sum;
    output [31:0] sub;

    SB_MAC16 i_sbmac16_sum(
        .A(a_in[31:16]),
        .B(a_in[15:0]),
        .C(b_in[31:16]), 
        .D(b_in[15:0]),
        .O(sum),
        .CLK(clk), //clock
        .CE(1'b1), // clock enable
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
        .ADDSUBTOP(1'b0), //0 for add
        .ADDSUBBOT(1'b0), //0 for add
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
defparam i_sbmac16_sum.B_SIGNED = 1'b0; // don't register A 
defparam i_sbmac16_sum.A_SIGNED = 1'b0; // don't register B
defparam i_sbmac16_sum.MODE_8x8 = 1'b1; //1 gives power saving
defparam i_sbmac16_sum.BOTADDSUB_CARRYSELECT = 2'b00; //no carry in 
defparam i_sbmac16_sum.BOTADDSUB_UPPERINPUT = 1'b1;// input D 
defparam i_sbmac16_sum.BOTADDSUB_LOWERINPUT = 2'b00;//input B
defparam i_sbmac16_sum.BOTOUTPUT_SELECT = 2'b00; //Adder/Subtractor, not registered
defparam i_sbmac16_sum.TOPADDSUB_CARRYSELECT = 2'b10;// Cascade ACCUMOUT from lower Adder/Subtractor
defparam i_sbmac16_sum.TOPADDSUB_UPPERINPUT = 1'b1; //input C
defparam i_sbmac16_sum.TOPADDSUB_LOWERINPUT = 2'b00; //input A for adder/subtractor
defparam i_sbmac16_sum.TOPOUTPUT_SELECT = 2'b00; //00 for add/subtract
defparam i_sbmac16_sum.PIPELINE_16x16_MULT_REG2 = 1'b0; //don't register 16x16 multiplier output
defparam i_sbmac16_sum.PIPELINE_16x16_MULT_REG1 = 1'b0; //don't register 16x16 multiplier output
defparam i_sbmac16_sum.BOT_8x8_MULT_REG = 1'b0 ; //don't register bottom multiplier output
defparam i_sbmac16_sum.TOP_8x8_MULT_REG = 1'b0 ;//don't register top multiplier output
defparam i_sbmac16_sum.D_REG = 1'b0 ; // don't register D
defparam i_sbmac16_sum.B_REG = 1'b0 ; // don't register B
defparam i_sbmac16_sum.A_REG = 1'b0 ; // don't register A
defparam i_sbmac16_sum.C_REG = 1'b0 ; // don't register C 
defparam i_sbmac16_sum.NEG_TRIGGER = 1'b0; //detect rising edge 

    SB_MAC16 i_sbmac16_sub(
        .A(a_in[31:16]),
        .B(a_in[15:0]),
        .C(b_in[31:16]), 
        .D(b_in[15:0]),
        .O(sub),
        .CLK(clk), //clock
        .CE(1'b1), // clock enable
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
        .ADDSUBTOP(1'b1), //1 for sub
        .ADDSUBBOT(1'b1), //1 for sub
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
defparam i_sbmac16_sub.BOTADDSUB_CARRYSELECT = 2'b00; //00 for 0 carry in
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