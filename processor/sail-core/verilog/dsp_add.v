module dsp_add(a_in, b_in, sum);
    input [31:0] a_in;
    input [31:0] b_in;
    output [31:0] sum;

    SB_MAC16 i_sbmac16_sum(
        .A(a_in[31:16]),
        .B(a_in[15:0]),
        .C(b_in[31:16]), 
        .D(b_in[15:0]),
        .O(sum),
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

endmodule