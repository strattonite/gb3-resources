/*
	Authored 2018-2019, Ryan Voo.

	All rights reserved.
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

	*	Redistributions of source code must retain the above
		copyright notice, this list of conditions and the following
		disclaimer.

	*	Redistributions in binary form must reproduce the above
		copyright notice, this list of conditions and the following
		disclaimer in the documentation and/or other materials
		provided with the distribution.

	*	Neither the name of the author nor the names of its
		contributors may be used to endorse or promote products
		derived from this software without specific prior written
		permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
*/



/*
 *	cpu top-level
 */



module cpu(
			clk,
			inst_mem_in,
			inst_mem_out,
			data_mem_out,
			data_mem_addr,
			data_mem_WrData,
			data_mem_memwrite,
			data_mem_memread,
			data_mem_sign_mask
		);
	/*
	 *	Input Clock
	 */
	input clk;

	/*
	 *	instruction memory input
	 */
	output [31:0]		inst_mem_in; // address memory instruction wanted next
	input [31:0]		inst_mem_out; // actual memory instruction for fetched this cycle

	/*
	 *	Data Memory
	 */
	input [31:0]		data_mem_out; // data coming from memory
	output [31:0]		data_mem_addr;
	output [31:0]		data_mem_WrData;
	output			data_mem_memwrite;
	output			data_mem_memread;
	output [3:0]		data_mem_sign_mask;

	/*
	 *	Program Counter
	 */
	wire [31:0]		pc_mux0; // pc_in if not branching
	wire [31:0]		pc_in;
	wire [31:0]		pc_out;
	wire			pcsrc; // trigger branching
	wire [31:0]		inst_mux_out; // the actual insruction - either a stall instruction or the actual fetched
	wire [31:0]		fence_mux_out;

	/*
	 *	Pipeline Registers
	 */
	wire [63:0]		if_id_out; // output of fetch/decode pipeline register
	wire [177:0]		id_ex_out; // output of execute pipeline register
	wire [154:0]		ex_mem_out;
	wire [116:0]		mem_wb_out;

	/*
	 *	Control signals
	 */
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

	/*
	 *	Decode stage
	 */
	wire [31:0]		cont_mux_out; // contains stall or the type of instructino it is
	wire [31:0]		regA_out;
	wire [31:0]		regB_out;
	wire [31:0]		imm_out;
	wire [31:0]		RegA_mux_out;
	wire [31:0]		RegB_mux_out;
	wire [31:0]		RegA_AddrFwdFlush_mux_out;
	wire [31:0]		RegB_AddrFwdFlush_mux_out;
	wire [31:0]		rdValOut_CSR;
	wire [3:0]		dataMem_sign_mask;

	/*
	 *	Execute stage
	 */
	wire [31:0]		ex_cont_mux_out;
	wire [31:0]		addr_adder_mux_out;
	wire [31:0]		alu_mux_out;
	wire [31:0]		addr_adder_sum;
	wire [6:0]		alu_ctl; // alu control signal
	wire			alu_branch_enable;
	wire [31:0]		alu_result; // output from alu
	wire [31:0]		lui_result; // address to write to
	
	/*
	 *	Memory access stage
	 */
	wire [31:0]		auipc_mux_out;
	wire [31:0]		mem_csrr_mux_out;
	wire[31:0] mem_regwb_mux_out;

	/*
	 *	Writeback to registers stage
	 */
	wire [31:0]		wb_mux_out;
	wire [31:0]		reg_dat_mux_out;

	/*
	 *	Forwarding multiplexer wires
	 */
	wire [31:0]		dataMemOut_fwd_mux_out; // lui or data from memory
	wire [31:0]		mem_fwd1_mux_out; // memory stage forward data
	wire [31:0]		mem_fwd2_mux_out; // memory stage forward data
	wire [31:0]		wb_fwd1_mux_out; // write back stage forward data
	wire [31:0]		wb_fwd2_mux_out; // write back stage forward data
	wire			mfwd1; // forwarding from memory stage?
	wire			mfwd2; // forwarding from memory stage?
	wire			wfwd1; // forwarding from write back stage?
	wire			wfwd2; // forwarding from write back stage?

	/*
	 *	Branch Predictor
	 */
	wire [31:0]		pc_adder_out;
	wire [31:0]		branch_predictor_addr;
	wire			predict; // whether branch prediction used or not for this cycle
	wire [31:0]		branch_predictor_mux_out;
	wire			actual_branch_decision;
	wire			mistake_trigger;
	wire			decode_ctrl_mux_sel;
	wire			inst_mux_sel;

	/*
	 *	Instruction Fetch Stage
	 */


	mux2to1 pc_mux(
			.input0(pc_mux0),
			.input1(ex_mem_out[72:41]), // addr_adder_sum
			.select(pcsrc), // branching?
			.out(pc_in)
		); // selects out pc_in, which will be the next instruction fetched

	adder pc_adder(
			.input1(32'b100),
			.input2(pc_out),
			.out(pc_adder_out)
		); // increments pc_out by 4 - because every instruction if 4 bytes long

	program_counter PC(
			.inAddr(pc_in),
			.outAddr(pc_out),
			.clk(clk)
		); // instantiates program counter - every clock sets pc_out = pc_in

	mux2to1 inst_mux(
			.input0(inst_mem_out),
			.input1(32'b0),
			.select(inst_mux_sel), // do we need to flush?
			.out(inst_mux_out)
		); // the actual insruction - either a stall instruction or the actual fetched

	mux2to1 fence_mux(
			.input0(pc_adder_out),
			.input1(pc_out),
			.select(Fence_signal),
			.out(fence_mux_out)
		); // TODO fenceing stuff. if fencing uses

	/*
	 *	IF/ID Pipeline Register - Insturction fetch/instruction decode
	 */
	if_id if_id_reg(
			.clk(clk),
			.data_in({inst_mux_out, pc_out}),
			.data_out(if_id_out)
		); // puts the output of inst_mux_out with pc_out into register

		// if_id_out[63:32] = inst_mux_out
		// if_id_out[31:0] = pc_out

	/*
	 *	Decode Stage
	 */
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
			.CSRR(CSRR_signal)
		); // control unit. the opcode is defined by the first last bits of the instruction
		// the other outputs state what type of instruction it is

	mux2to1 cont_mux(
			.input0({21'b0, Jalr1, ALUSrc1, Lui1, Auipc1, Branch1, MemRead1, MemWrite1, CSRR_signal, RegWrite1, MemtoReg1, Jump1}),
			.input1(32'b0),
			.select(decode_ctrl_mux_sel), // do we need to flush?
			.out(cont_mux_out)
		); // decides whether is stall or not

	regfile register_files(
			.clk(clk),
			.write(ex_mem_out[2]),
			.wrAddr(ex_mem_out[142:138]),
			.wrData(reg_dat_mux_out),
			.rdAddrA(inst_mux_out[19:15]), // 19:15 is the rs1 except for U-type isntructions
			.rdDataA(regA_out),
			.rdAddrB(inst_mux_out[24:20]), // 24:20 is rs2 excpet for I and U type
			.rdDataB(regB_out)
		); // the register file TODO, what is it writing

	imm_gen immediate_generator(
			.inst(if_id_out[63:32]), 
			.imm(imm_out)
		); // generates the immedaite given the instruction

	ALUControl alu_control(
			.Opcode(if_id_out[38:32]), // the opcode
			.FuncCode({if_id_out[62], if_id_out[46:44]}), // if_id_out[46:44] is funct3 // if_id_out[62] contrls bit shifting
			.ALUCtl(alu_ctl)
		); // alu controller. opcode and func code taken from output of pipeline register

	sign_mask_gen sign_mask_gen_inst(
			.func3(if_id_out[46:44]),
			.sign_mask(dataMem_sign_mask)
		); // generates mask based on funct3? TODO doesn't match up with instruction set docs tho

	csr_file ControlAndStatus_registers(
			.clk(clk),
			.write(mem_wb_out[3]), //TODO
			.wrAddr_CSR(mem_wb_out[116:105]),
			.wrVal_CSR(mem_wb_out[35:4]),
			.rdAddr_CSR(inst_mux_out[31:20]), // 12 bit immedaite in U type instruction
			.rdVal_CSR(rdValOut_CSR)
		); // TODO

	mux2to1 RegA_mux(
			.input0(regA_out), // output from register file TODO
			.input1({27'b0, if_id_out[51:47]}), // if_id_out[51:47] is rs1
			.select(CSRRI_signal),
			.out(RegA_mux_out)
		); // todo

	mux2to1 RegB_mux(
			.input0(regB_out), // output from register file TODO
			.input1(rdValOut_CSR), // output from control signal register
			.select(CSRR_signal),
			.out(RegB_mux_out)
		); // todo

	mux2to1 RegA_AddrFwdFlush_mux( //TODO cleanup
			.input0({27'b0, if_id_out[51:47]}), // if_id_out[51:47] is rs1
			.input1(32'b0), // stall?
			.select(CSRRI_signal),
			.out(RegA_AddrFwdFlush_mux_out)
		); // TODO similar to RegA_mux but has an empty input - flushing?

	mux2to1 RegB_AddrFwdFlush_mux( //TODO cleanup
			.input0({27'b0, if_id_out[56:52]}), // rs2
			.input1(32'b0), // stall?
			.select(CSRR_signal),
			.out(RegB_AddrFwdFlush_mux_out)
		); // TODO similar to RegB_mux but has an empty input - flushing?

	assign CSRRI_signal = CSRR_signal & (if_id_out[46]); // if_id_out[46] is highest bit of funct3

	//ID/EX Pipeline Register
	id_ex id_ex_reg(
			.clk(clk),
			.data_in({if_id_out[63:52], RegB_AddrFwdFlush_mux_out[4:0], RegA_AddrFwdFlush_mux_out[4:0], if_id_out[43:39], dataMem_sign_mask, alu_ctl, imm_out, RegB_mux_out, RegA_mux_out, if_id_out[31:0], cont_mux_out[10:7], predict, cont_mux_out[6:0]}),
			.data_out(id_ex_out)
		);

	// [177:166] is immedaite in U type instruction
	// [165:161] is rs2 or stall
	// [160: 156] is rs1 or stall
	// [155: 151] is rd or immediates
	// [150:147] is the dat mask
	// [146:140] is alu control signal
	// [139:108] is the immediate
	// [107:76] is RegB mux output
	// [75:44] is RegA mux output
	// [43:12] is isntruction address or pc_out
	// [11:8] is {Jalr1, ALUSrc1, Lui1, Auipc1}
	// [7] is predict
	// [6:0] {Branch1, MemRead1, MemWrite1, CSRR_signal, RegWrite1, MemtoReg1, Jump1}

	//Execute stage
	mux2to1 ex_cont_mux(
			.input0({23'b0, id_ex_out[8:0]}),
			.input1(32'b0), // stall? TODO
			.select(pcsrc),
			.out(ex_cont_mux_out)
		); // selects between control signals and predict 

	mux2to1 addr_adder_mux(
			.input0(id_ex_out[43:12]), // this is pc_out
			.input1(wb_fwd1_mux_out), // operand forwarding stuff? TODO
			.select(id_ex_out[11]), // if the control signal is jalr1 from cont_mux_out
			.out(addr_adder_mux_out) // so if is JALR instruction use the operand forwarded
		);

	adder addr_adder(
			.input1(addr_adder_mux_out), 
			.input2(id_ex_out[139:108]), // imm out
			.out(addr_adder_sum) // add the imm to the previous iytoyt
		);

	mux2to1 alu_mux(
			.input0(wb_fwd2_mux_out), // TODO: i'm thinking this is value from the register
			// if the second operand is from register then it needs to be loaded so the value is forwarded???
			.input1(id_ex_out[139:108]), // imm out
			.select(id_ex_out[10]), // loads imm if ALUSrc1 - which tells if ALU second operand is immediate value of from register
			.out(alu_mux_out) // the second operand for ALU
		);

	alu alu_main(
			.ALUctl(id_ex_out[146:140]), // this is alu control signal
			.A(wb_fwd1_mux_out), // TODO: i think this is forwarded operand value
			.B(alu_mux_out), // opearand B
			.ALUOut(alu_result),
			.Branch_Enable(alu_branch_enable) // are we branching?
		); // actual alu

	mux2to1 lui_mux(
			.input0(alu_result),
			.input1(id_ex_out[139:108]), // imm out
			.select(id_ex_out[9]), // is it a LUI instruction?
			.out(lui_result) // if it's LUI instruction then just take the immediate, otherwise take the ALU output
		);

	//EX/MEM Pipeline Register
	ex_mem ex_mem_reg(
			.clk(clk),
			.data_in({id_ex_out[177:166], id_ex_out[155:151], wb_fwd2_mux_out, lui_result, alu_branch_enable, addr_adder_sum, id_ex_out[43:12], ex_cont_mux_out[8:0]}),
			.data_out(ex_mem_out)
		);

	// [154:143] immediate in U type instruction
	// [142: 138] rd or immediate depending on instruction
	// [137:106] TODO operand 2 forwarding?
	// [105:74] lui result, i think is the result to write
	// [73] branching?
	// [72:41] TODO addr_adder_sum
	// [40:9] instruction address
	// [8:0] {Auipc1 ,predict ,Branch1, MemRead1, MemWrite1, CSRR_signal, RegWrite1, MemtoReg1, Jump1}

	//Memory Access Stage
	branch_decision branch_decide(
			.Branch(ex_mem_out[6]), // Branch1
			.Predicted(ex_mem_out[7]), // predict
			.Branch_Enable(ex_mem_out[73]), // branching?
			.Jump(ex_mem_out[0]), // jump1
			.Mispredict(mistake_trigger), // TODO whether mistake was miade?
			.Decision(actual_branch_decision), // TODO branch deicsion
			.Branch_Jump_Trigger(pcsrc) // branch trigger
		); 

	mux2to1 auipc_mux(
			.input0(ex_mem_out[105:74]), // lui result
			.input1(ex_mem_out[72:41]), // addr_adder_sum
			.select(ex_mem_out[8]), // Auipc instruction
			.out(auipc_mux_out) // if its Auipc will take addr_adder_sum which is the instruction address summed with immediate
		);

	mux2to1 mem_csrr_mux(
			.input0(auipc_mux_out), // auipc result
			.input1(ex_mem_out[137:106]), // TODO operand 2 forwarding?
			.select(ex_mem_out[3]), // CSRR signal
			.out(mem_csrr_mux_out) 
		);

	//MEM/WB Pipeline Register
	mem_wb mem_wb_reg(
			.clk(clk),
			.data_in({ex_mem_out[154:143], ex_mem_out[142:138], data_mem_out, mem_csrr_mux_out, ex_mem_out[105:74], ex_mem_out[3:0]}),
			.data_out(mem_wb_out)
		);
	
	// [116:105] immediate value
	// [104:100] rd or immediate value
	// [99:68] data_mem_out
	// [67:36] mem_csrr_mux_out
	// [35:4] lui_result
	// [3:0] is {CSRR_signal, RegWrite1, MemtoReg1, Jump1}

	//Writeback to Register Stage
	mux2to1 wb_mux(
			.input0(mem_wb_out[67:36]), // mem_csrr_mux_out
			.input1(mem_wb_out[99:68]), // data_mem_out
			.select(mem_wb_out[1]), // MemtoReg
			.out(wb_mux_out) // 
		);

	mux2to1 reg_dat_mux( //TODO cleanup
			.input0(mem_regwb_mux_out),
			.input1(id_ex_out[43:12]), // 2 cycles ago instruction address
			.select(ex_mem_out[0]), // 1 cyle ago mem to reg
			.out(reg_dat_mux_out)
		);

	//Forwarding Unit
	ForwardingUnit forwarding_unit(
			.rs1(id_ex_out[160:156]), // rs1 from between decode and execute
			.rs2(id_ex_out[165:161]), // rs2 from between decode and execute
			.MEM_RegWriteAddr(ex_mem_out[142:138]), // rd or immediate between execute and memory access
			.WB_RegWriteAddr(mem_wb_out[104:100]),  // rd or immediate between memory and writeback
			.MEM_RegWrite(ex_mem_out[2]), // Regwrite from execute/memory 
			.WB_RegWrite(mem_wb_out[2]),// Regwrite from memory/write back
			.EX_CSRR_Addr(id_ex_out[177:166]), // Immediate in from decode/execute
			.MEM_CSRR_Addr(ex_mem_out[154:143]), // immediate from execute/mem
			.WB_CSRR_Addr(mem_wb_out[116:105]), // immediate from mem/wb
			.MEM_CSRR(ex_mem_out[3]), // csrr from execute/mem
			.WB_CSRR(mem_wb_out[3]), // csrr from mem/wb
			.MEM_fwd1(mfwd1), 
			.MEM_fwd2(mfwd2),
			.WB_fwd1(wfwd1),
			.WB_fwd2(wfwd2)
		);

	mux2to1 mem_fwd1_mux(
			.input0(id_ex_out[75:44]), // regA mux output
			.input1(dataMemOut_fwd_mux_out), 
			.select(mfwd1), // forwarding from memory stage?
			.out(mem_fwd1_mux_out) // memory forward 
		);

	mux2to1 mem_fwd2_mux(
			.input0(id_ex_out[107:76]), // regB mux output
			.input1(dataMemOut_fwd_mux_out),
			.select(mfwd2),
			.out(mem_fwd2_mux_out) 
	); // works out forward data from memory stage

	mux2to1 wb_fwd1_mux(
			.input0(mem_fwd1_mux_out),
			.input1(wb_mux_out),
			.select(wfwd1),
			.out(wb_fwd1_mux_out)
		); // works out forward data fromw riteback

	mux2to1 wb_fwd2_mux(
			.input0(mem_fwd2_mux_out),
			.input1(wb_mux_out),
			.select(wfwd2),
			.out(wb_fwd2_mux_out)
		);

	mux2to1 dataMemOut_fwd_mux(
			.input0(ex_mem_out[105:74]), // lui result
			.input1(data_mem_out), // or data from memory
			.select(ex_mem_out[1]), // MemToReg
			.out(dataMemOut_fwd_mux_out) // selects data to be forwarded for memory stage
		);

	//Branch Predictor
	branch_predictor branch_predictor_FSM(
			.clk(clk),
			.actual_branch_decision(actual_branch_decision),
			.branch_decode_sig(cont_mux_out[6]), // branching from decode stage
			.branch_mem_sig(ex_mem_out[6]), // branching from execute stage
			.in_addr(if_id_out[31:0]), // address between fetch/
			.offset(imm_out), // imeediate value from decode
			.branch_addr(branch_predictor_addr), // predicted address
			.prediction(predict) // are we predciting?
		);

	mux2to1 branch_predictor_mux(
			.input0(fence_mux_out), // fence address
			.input1(branch_predictor_addr), // predicted address
			.select(predict), // predicting?
			.out(branch_predictor_mux_out) // selec the predicted address
		);

	mux2to1 mistaken_branch_mux(
			.input0(branch_predictor_mux_out), // branch predictor output
			.input1(id_ex_out[43:12]), // pc_out
			.select(mistake_trigger), // mistake?
			.out(pc_mux0) // if not branching
		);

	 //TODO copy of wb_mux but in mem stage, move back and cleanup
	//A copy of the writeback mux, but in MEM stage //TODO move back and cleanup
	mux2to1 mem_regwb_mux(
			.input0(mem_csrr_mux_out),
			.input1(data_mem_out),
			.select(ex_mem_out[1]),
			.out(mem_regwb_mux_out)
		);

	//OR gate assignments, used for flushing
	assign decode_ctrl_mux_sel = pcsrc | mistake_trigger; // branching or mistake?
	assign inst_mux_sel = pcsrc | predict | mistake_trigger | Fence_signal;

	//Instruction Memory Connections
	// assings the memory instruction it wants next stored in pc_out
	assign inst_mem_in = pc_out;
	

	//Data Memory Connections
	assign data_mem_addr = lui_result;
	assign data_mem_WrData = wb_fwd2_mux_out;
	assign data_mem_memwrite = ex_cont_mux_out[4];
	assign data_mem_memread = ex_cont_mux_out[5];
	assign data_mem_sign_mask = id_ex_out[150:147];
endmodule
