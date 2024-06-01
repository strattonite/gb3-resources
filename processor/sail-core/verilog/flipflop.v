module flipflopclk(hf_clk, clk);
    input hf_clk;
    output wire clk;
    wire clk1;
    
    SB_DFF SB_DFF_inst1(
        .Q(clk1),
        .C(hf_clk),
        .D(1'b1)
    );
    
    SB_DFF SB_DFF_inst2(
        .Q(clk),
        .C(clk1),
        .D(1'b1)
    );
endmodule