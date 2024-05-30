`timescale 1ns/1ns
module tb_instruction_gen;
    reg clk;
    wire [179:0]     data_in;
    wire [177:0]    data_out;
    wire [177:0]    id_ex_out;
    reg [31:0]		instruction_memory[0:2**11];
    reg [31:0]      pc;
    wire [31:0]     pc_out;
    wire            stall_clk;
    wire [31:0]     inst_out;
    reg [31:0]      inst_reg;
    wire [63:0]     if_id_out;

    wire			MemtoReg1;
	wire			RegWrite1;
	wire			MemWrite1;
	wire			MemRead1;
	wire			Branch1;
	wire			Jump1;
	wire			Jalr1;
	wire			ALUSrc1;
	wire			Lui1;
	wire			Auipc1;
	wire			Fence_signal;
	wire			CSRR_signal;
	wire			CSRRI_signal;
	wire 			RS1;
	wire			RS2;

    wire [6:0]		alu_ctl;
    wire [31:0]		imm_out;
    wire			predict;
    wire [3:0]	    dataMem_sign_mask;

    assign predict = 1'b0;
    assign data_in = {RS1, RS2, if_id_out[63:52], if_id_out[56:52], if_id_out[51:47], if_id_out[43:39], dataMem_sign_mask, alu_ctl, imm_out, 32'b0, 32'b0, if_id_out[31:0], Jalr1, ALUSrc1, Lui1, Auipc1, predict, Branch1, MemRead1, MemWrite1, CSRR_signal, RegWrite1, MemtoReg1, Jump1};

    if_id if_id_reg(
        .clk(clk),
        .data_in({inst_reg, pc}),
        .data_out(if_id_out)
    );

    control control_unit(
        .opcode({if_id_out[38:32]}),
        .MemtoReg(MemtoReg1),
        .RegWrite(RegWrite1),
        .MemWrite(MemWrite1),
        .MemRead(MemRead1),
        .Branch(Branch1),
        .ALUSrc(ALUSrc1),
        .Jump(Jump1),
        .Jalr(Jalr1),
        .Lui(Lui1),
        .Auipc(Auipc1),
        .Fence(Fence_signal),
        .CSRR(CSRR_signal),
        .RS1(RS1),
        .RS2(RS2)
    );

    ALUControl alu_control(
        .Opcode(if_id_out[38:32]),
        .FuncCode({if_id_out[62], if_id_out[46:44]}),
        .ALUCtl(alu_ctl)
    );

    imm_gen immediate_generator(
        .inst(if_id_out[63:32]),
        .imm(imm_out)
    );

    sign_mask_gen sign_mask_gen_inst(
        .func3(if_id_out[46:44]),
        .sign_mask(dataMem_sign_mask)
    );

    id_ex ex_reg(
        .clk(clk),
        .data_in(data_in[177:0]),
        .data_out(id_ex_out)
    );

    instruction_generator gen(
        .clk(clk),
        .data_in(data_in),
        .data_out(data_out),
        .stall_clk(stall_clk),
        .opcode(if_id_out[38:32])
    );

    initial begin
        clk <= 0;
        // data_in <= 180'b0;
        pc <= 32'b0;

        $readmemh("program.hex",instruction_memory);
        #10  
            inst_reg <= instruction_memory[0];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10 
            inst_reg <= instruction_memory[1];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[2];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[3];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[4];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[5];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
                #10  
            inst_reg <= instruction_memory[6];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[7];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[8];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[9];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[10];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[11];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[12];
            pc <= pc + 4;
            clk <= 1;
        
        #10 clk <= 0; 
        #10  
            inst_reg <= instruction_memory[13];
            clk <= 1;
        
        #10 clk <= 0; 
    end

    initial begin 
        // $monitor("opcode: %b\ndata_out : %04X\nid_ex_out: %04X\n", if_id_out[38:32], data_out, id_ex_out);
        $dumpfile("simpleTestbench.vcd");
        $dumpvars;
    end

endmodule