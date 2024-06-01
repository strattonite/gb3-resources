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
 *	RISC-V instruction memory
 */



module instruction_memory(addr, out, clk,  clk_stall);
	input [31:0]		addr;
	input clk;
	output reg[31:0]		out;
	output reg 			clk_stall;

	/*
	 *	Size the instruction memory.
	 *
	 *	(Bad practice: The constant should be a `define).
	 */
	 
	reg [31:0]		instruction_memory[0:2**10-1];
	reg[31:0] 		addr_buf;
	reg[31:0] 		word_buf;
	wire [31:0]		read_buf;

	integer state = 0;
	
	parameter		IDLE = 0;
	parameter		READ_BUFFER = 1;
	parameter		READ = 2;
	
	/*
	 *	According to the "iCE40 SPRAM Usage Guide" (TN1314 Version 1.0), page 5:
	 *
	 *		"SB_SPRAM256KA RAM does not support initialization through device configuration."
	 *
	 *	The only way to have an initializable memory is to use the Block RAM.
	 *	This uses Yosys's support for nonzero initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design.
	 */
	initial begin
		/*
		 *	read from "program.hex" and store the instructions in instruction memory
		 */
		$readmemh("verilog/program.hex",instruction_memory);
	end
	
	
	always @(negedge clk) begin
		/* TODO  
		test state machine*/
		case (state)
			IDLE: begin
				addr_buf <= addr;
				state <= READ_BUFFER;
				clk_stall <= 1;
				end
			

			READ_BUFFER: begin
				/*
				 *	Subtract out the size of the instruction memory.
				 *	(Bad practice: The constant should be a `define).
				 */
				word_buf <= instruction_memory[addr_buf >> 2];
				state <= READ;
				
			end

			READ: begin
				clk_stall <= 0;
				out <= instruction_memory[addr_buf >> 2];
				state <= IDLE;
			end

		endcase
	end
	
	
	// assign out = read_data;
	
	
endmodule
