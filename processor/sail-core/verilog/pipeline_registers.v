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

`define NOP 'hc00000048200000000000000000000000000000001004;

// [165:161] is rs2 or stall
// [160: 156] is rs1 or stall
// [155: 151] is rd or immediates

// JALR -> 11, ALUsrc -> 10, LUI -> 9, AUIPC -> 8
// BRANCH -> 6, MEMREAD -> 5, MEMWRITE -> 4, CSRR -> 3
// REGWRITE -> 2, MEM2REG -> 1, JUMP -> 0
// 179 -> RS1, 178 -> RS2
module dependency (inst_in, infl_in, dep_out);
	input [179:0]		inst_in;
	input [177:0]		infl_in;
	output 				dep_out;

	
					 // check RS1 RAW dependency
	assign dep_out = (infl_in != 178'b0) & ((inst_in[179] & (inst_in[160:156] == infl_in[155:151])) 
					 // check RS2 RAW dependency
					 || (inst_in[178] & (inst_in[165:161] == infl_in[155:151]))
					 // check if both ixs are lw's to same rd (WAW hazard)
					 || (inst_in[1] & infl_in[1] & (inst_in[155:151] == infl_in[155:151])));
endmodule


/*
 *	implement basic out of order execution with 3 instruction lookahead (loads/stores are 3 cycles)
 */
module instruction_generator (clk, data_in, data_out, stall_clk, opcode);
	input				clk;
	input [6:0]			opcode;
	// input { RS1, RS2, cnt_mux_out[177:0] }
	input [179:0]		data_in;
	// output to id_ex
	output reg [177:0]	data_out;
	// should we stall?
	output wire 		stall_clk;

	reg [179:0]			pending[2:0];
	reg [177:0]			inflight[2:0];

	wire[7:0] dep_out;

	initial begin
		pending[0] = 180'b0;
		pending[1] = 180'b0;
		pending[2] = 180'b0;

		inflight[0] = 178'b0;
		inflight[1] = 178'b0;
		inflight[2] = 178'b0;

		data_out <= 178'b0;

		$monitor(
			"data_in:\n%04x\nopcode: %b, rs1: %b, rs2: %b, regwrite: %b, rs2_add: %04x, rs1_add: %04x, rd: %04x\ndeps:\n%b\nexecs: [%b, %b, %b, %b]\ninflight:\n%04x\n%04x\n%04x\npending:\n%04x\n%04x\n%04x\ndata_out:\n%04x\nstall:%b\n",
			data_in, opcode, data_in[179], data_in[178], data_in[1], data_in[165:161], data_in[160:156], data_in[155:151], dep_out, exec_0, exec_1, exec_2, exec_3, inflight[0], inflight[1], inflight[2], pending[0], pending[1], pending[2], data_out, stall_clk
		);
	end

	wire exec_3;
	wire exec_2;
	wire exec_1;
	wire exec_0;
	// can we safely execute instruction?
	assign exec_3 = (~dep_out[6]) & (~dep_out[7]) & (pending[2] != 180'b0);
	assign exec_2 = (~dep_out[4]) & (~dep_out[5]) & (pending[1] != 180'b0);
	assign exec_1 = (~dep_out[2]) & (~dep_out[3]) & (pending[0] != 180'b0);
	assign exec_0 = (~dep_out[1]) & (~dep_out[0]) & (data_in != 180'b0);

	dependency dep_checker_1(data_in, inflight[1], dep_out[0]);
	dependency dep_checker_2(data_in, inflight[2], dep_out[1]);
	dependency dep_checker_3(pending[0], inflight[1], dep_out[2]);
	dependency dep_checker_4(pending[0], inflight[2], dep_out[3]);
	dependency dep_checker_5(pending[1], inflight[1], dep_out[4]);
	dependency dep_checker_6(pending[1], inflight[2], dep_out[5]);
	dependency dep_checker_7(pending[2], inflight[1], dep_out[6]);
	dependency dep_checker_8(pending[2], inflight[2], dep_out[7]);

	assign stall_clk = ~(
			exec_0 | 
			exec_1 | 
			exec_2 |
			exec_3 |
			(pending[0] == 180'b0) |
			(pending[1] == 180'b0) |
			(pending[2] == 180'b0)
		);

	// assign stall_clk = (pending[0] != 180'b0) | (pending[1] != 180'b0) | (pending[2] != 180'b0);
	// assign stall_clk = 1'b0;

	always @(posedge clk) begin
		// shift inflight registers first
		inflight[2] <= inflight[1];
		inflight[1] <= inflight[0];
		inflight[0] <= 178'b0;

		// data_out <= data_in[177:0];

		if (~stall_clk) begin
			if (exec_3) begin 
				// lw instruction sent to inflight queue
				if (pending[2][1]) begin 
					inflight[0] <= pending[2][177:0];
				end

				// buffer executing instruction
				data_out <= pending[2][177:0];

				// shift forward pending and insert data_in
				pending[2] <= pending[1];
				pending[1] <= pending[0];
				pending[0] <= data_in;

			end else if (exec_2) begin 
				if (pending[1][1]) begin 
					inflight[0] <= pending[2][177:0];
				end

				data_out <= pending[1][177:0];

				pending[1] <= pending[0];
				pending[0] <= data_in;
			end else if (exec_1) begin
				if (pending[0][1]) begin 
					inflight[0] <= pending[0][177:0];
				end

				data_out <= pending[0][177:0];
				pending[0] <= data_in;
			end else if (exec_0) begin
				// data_in has immediately executed
				if (data_in[1]) begin 
					inflight[0] <= data_in[177:0];
				end

				data_out <= data_in[177:0];
			end else begin 
				data_out <= `NOP;
				pending[2] <= pending[1];
				pending[1] <= pending[0];
				pending[0] <= data_in;
			end
		end
	end
endmodule

/* IF/ID pipeline registers */ 
module if_id (clk, data_in, data_out);
	input			clk;
	input [63:0]		data_in;
	output reg[63:0]	data_out;

	/*
	 *	This uses Yosys's support for nonzero initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design.
	 */
	initial begin
		data_out = 64'b0;
	end

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule



/* ID/EX pipeline registers */ 
module id_ex (clk, data_in, data_out);
	input			clk;
	input [177:0]		data_in;
	output reg[177:0]	data_out;

	/*
	 *	The `initial` statement below uses Yosys's support for nonzero
	 *	initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design and to thereby set the values.
	 */
	initial begin
		data_out = 178'b0;
	end

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule



/* EX/MEM pipeline registers */ 
module ex_mem (clk, data_in, data_out);
	input			clk;
	input [154:0]		data_in;
	output reg[154:0]	data_out;

	/*
	 *	The `initial` statement below uses Yosys's support for nonzero
	 *	initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design and to thereby set the values.
	 */
	initial begin
		data_out = 155'b0;
	end

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule



/* MEM/WB pipeline registers */ 
module mem_wb (clk, data_in, data_out);
	input			clk;
	input [116:0]		data_in;
	output reg[116:0]	data_out;

	/*
	 *	The `initial` statement below uses Yosys's support for nonzero
	 *	initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design and to thereby set the values.
	 */
	initial begin
		data_out = 117'b0;
	end

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule
