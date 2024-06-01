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

module mem_logic(clk, addr_buf, sign_mask_buf, word_buf, read_buf, write_data_buffer, replacement_word);
	input				clk;
	input [31:0] 		addr_buf;
	input [3:0]			sign_mask_buf;
	input [31:0]		word_buf;

	output wire [31:0]	read_buf;
	output wire [31:0]	replacement_word;
	input [31:0]		write_data_buffer;

	wire [9:0]		addr_buf_block_addr;
	wire [1:0]		addr_buf_byte_offset;

	assign			addr_buf_block_addr	= addr_buf[11:2];
	assign			addr_buf_byte_offset	= addr_buf[1:0];

	wire select0;
	wire select1;
	wire select2;

	wire[31:0] out1;
	wire[31:0] out2;
	wire[31:0] out3;
	wire[31:0] out4;
	wire[31:0] out5;
	wire[31:0] out6;

	wire [7:0]		buf0;
	wire [7:0]		buf1;
	wire [7:0]		buf2;
	wire [7:0]		buf3;

	assign 			buf0	= word_buf[7:0];
	assign 			buf1	= word_buf[15:8];
	assign 			buf2	= word_buf[23:16];
	assign 			buf3	= word_buf[31:24];

	assign select0 = (~sign_mask_buf[2] & ~sign_mask_buf[1] & ~addr_buf_byte_offset[1] & addr_buf_byte_offset[0]) | (~sign_mask_buf[2] & addr_buf_byte_offset[1] & addr_buf_byte_offset[0]) | (~sign_mask_buf[2] & sign_mask_buf[1] & addr_buf_byte_offset[1]);
	assign select1 = (~sign_mask_buf[2] & ~sign_mask_buf[1] & addr_buf_byte_offset[1]) | (sign_mask_buf[2] & sign_mask_buf[1]); 
	assign select2 = sign_mask_buf[1];

	assign out1 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{24{buf1[7]}}, buf1} : {24'b0, buf1}) : ((sign_mask_buf[3]==1'b1) ? {{24{buf0[7]}}, buf0} : {24'b0, buf0});
	assign out2 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{24{buf3[7]}}, buf3} : {24'b0, buf3}) : ((sign_mask_buf[3]==1'b1) ? {{24{buf2[7]}}, buf2} : {24'b0, buf2});
	assign out3 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{16{buf3[7]}}, buf3, buf2} : {16'b0, buf3, buf2}) : ((sign_mask_buf[3]==1'b1) ? {{16{buf1[7]}}, buf1, buf0} : {16'b0, buf1, buf0});
	assign out4 = (select0) ? 32'b0 : {buf3, buf2, buf1, buf0};

	assign out5 = (select1) ? out2 : out1;
	assign out6 = (select1) ? out4 : out3;

	assign read_buf = (select2) ? out6 : out5;

	wire bdec_sig0;
	wire bdec_sig1;
	wire bdec_sig2;
	wire bdec_sig3;

	assign bdec_sig0 = (~addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
	assign bdec_sig1 = (~addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);
	assign bdec_sig2 = (addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
	assign bdec_sig3 = (addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);

	wire[7:0] byte_r0;
	wire[7:0] byte_r1;
	wire[7:0] byte_r2;
	wire[7:0] byte_r3;

	assign byte_r0 = (bdec_sig0==1'b1) ? write_data_buffer[7:0] : buf0;
	assign byte_r1 = (bdec_sig1==1'b1) ? write_data_buffer[7:0] : buf1;
	assign byte_r2 = (bdec_sig2==1'b1) ? write_data_buffer[7:0] : buf2;
	assign byte_r3 = (bdec_sig3==1'b1) ? write_data_buffer[7:0] : buf3;

	wire[15:0] halfword_r0;
	wire[15:0] halfword_r1;

	assign halfword_r0 = (addr_buf_byte_offset[1]==1'b1) ? {buf1, buf0} : write_data_buffer[15:0];
	assign halfword_r1 = (addr_buf_byte_offset[1]==1'b1) ? write_data_buffer[15:0] : {buf3, buf2};


	wire write_select0;
	wire write_select1;

	wire[31:0] write_out1;
	wire[31:0] write_out2;

	assign write_select0 = ~sign_mask_buf[2] & sign_mask_buf[1];
	assign write_select1 = sign_mask_buf[2];

	assign write_out1 = (write_select0) ? {halfword_r1, halfword_r0} : {byte_r3, byte_r2, byte_r1, byte_r0};
	assign write_out2 = (write_select0) ? 32'b0 : write_data_buffer;

	assign replacement_word = (write_select1) ? write_out2 : write_out1;
endmodule

// module write_logic(clk, addr_buf, sign_mask_buf, word_buf, write_data_buffer, replacement_word);
// 	input				clk;
// 	input [31:0] 		addr_buf;
// 	input [3:0]			sign_mask_buf;
// 	input [31:0]		write_data_buffer;
// 	input [31:0]		word_buf;

// 	output wire [31:0]	replacement_word;

// 	wire [9:0]		addr_buf_block_addr;
// 	wire [1:0]		addr_buf_byte_offset;

// 	assign			addr_buf_block_addr	= addr_buf[11:2];
// 	assign			addr_buf_byte_offset	= addr_buf[1:0];

// 	wire [7:0]		buf0;
// 	wire [7:0]		buf1;
// 	wire [7:0]		buf2;
// 	wire [7:0]		buf3;

// 	assign 			buf0	= word_buf[7:0];
// 	assign 			buf1	= word_buf[15:8];
// 	assign 			buf2	= word_buf[23:16];
// 	assign 			buf3	= word_buf[31:24];

// 	wire bdec_sig0;
// 	wire bdec_sig1;
// 	wire bdec_sig2;
// 	wire bdec_sig3;

// 	assign bdec_sig0 = (~addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
// 	assign bdec_sig1 = (~addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);
// 	assign bdec_sig2 = (addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
// 	assign bdec_sig3 = (addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);

// 	wire[7:0] byte_r0;
// 	wire[7:0] byte_r1;
// 	wire[7:0] byte_r2;
// 	wire[7:0] byte_r3;

// 	assign byte_r0 = (bdec_sig0==1'b1) ? write_data_buffer[7:0] : buf0;
// 	assign byte_r1 = (bdec_sig1==1'b1) ? write_data_buffer[7:0] : buf1;
// 	assign byte_r2 = (bdec_sig2==1'b1) ? write_data_buffer[7:0] : buf2;
// 	assign byte_r3 = (bdec_sig3==1'b1) ? write_data_buffer[7:0] : buf3;

// 	wire[15:0] halfword_r0;
// 	wire[15:0] halfword_r1;

// 	assign halfword_r0 = (addr_buf_byte_offset[1]==1'b1) ? {buf1, buf0} : write_data_buffer[15:0];
// 	assign halfword_r1 = (addr_buf_byte_offset[1]==1'b1) ? write_data_buffer[15:0] : {buf3, buf2};


// 	wire write_select0;
// 	wire write_select1;

// 	wire[31:0] write_out1;
// 	wire[31:0] write_out2;

// 	assign write_select0 = ~sign_mask_buf[2] & sign_mask_buf[1];
// 	assign write_select1 = sign_mask_buf[2];

// 	assign write_out1 = (write_select0) ? {halfword_r1, halfword_r0} : {byte_r3, byte_r2, byte_r1, byte_r0};
// 	assign write_out2 = (write_select0) ? 32'b0 : write_data_buffer;

// 	assign replacement_word = (write_select1) ? write_out2 : write_out1;
// endmodule

//Data cache

`define READ = 2'b01;
`define WRITE = 2'b10;
`define NONE = 2'b00;

module data_mem (clk, addr, write_data, memwrite, memread, sign_mask, read_data, led);
	input				clk;
	input [31:0]		addr;
	input [31:0]		write_data;
	input				memwrite;
	input				memread;
	input [3:0]			sign_mask;
	output reg [31:0]	read_data;
	output [7:0]		led;

	/*
	 *	led register
	 */
	reg [31:0]		led_reg;

	parameter		IDLE = 0;
	parameter		READ = 2;
	parameter		WRITE = 3;
	parameter 		READ_BUFFER = 4;

	reg[1:0] 		states[1:0];
	reg [31:0]		word_bufs[1:0];
	wire [31:0]		read_bufs[1:0];
	reg [31:0]		write_data_buffers[1:0];
	wire [31:0]		replacement_words[1:0];
	reg [31:0]		addr_bufs[1:0];
	reg [3:0]		sign_mask_bufs[1:0];
	reg [31:0]		data_block[0:127];
	reg [1:0]		memread_bufs;
	reg [1:0]		memwrite_bufs;

	// integer i;

	mem_logic rl0(
		.clk(clk),
		.addr_buf(addr_bufs[0]),
		.sign_mask_buf(sign_mask_bufs[0]),
		.word_buf(word_bufs[0]),
		.read_buf(read_bufs[0]),
		.write_data_buffer(write_data_buffers[0]),
		.replacement_word(replacement_words[0])
	);
	mem_logic rl1(
		.clk(clk),
		.addr_buf(addr_bufs[1]),
		.sign_mask_buf(sign_mask_bufs[1]),
		.word_buf(word_bufs[1]),
		.read_buf(read_bufs[1]),
		.write_data_buffer(write_data_buffers[1]),
		.replacement_word(replacement_words[1])
	);
	// read_logic rl2(
	// 	.clk(clk),
	// 	.addr_buf(addr_bufs[2]),
	// 	.sign_mask_buf(sign_mask_bufs[2]),
	// 	.word_buf(word_bufs[2]),
	// 	.read_buf(read_bufs[2])
	// );
	// write_logic wl0(
	// 	.clk(clk),
	// 	.addr_buf(addr_bufs[0]),
	// 	.sign_mask_buf(sign_mask_bufs[0]),
	// 	.word_buf(word_bufs[0]),
	// 	.write_data_buffer(write_data_buffers[0]),
	// 	.replacement_word(replacement_words[0])
	// );
	// write_logic wl1(
	// 	.clk(clk),
	// 	.addr_buf(addr_bufs[1]),
	// 	.sign_mask_buf(sign_mask_bufs[1]),
	// 	.word_buf(word_bufs[1]),
	// 	.write_data_buffer(write_data_buffers[1]),
	// 	.replacement_word(replacement_words[1])
	// );
	// write_logic wl2(
	// 	.clk(clk),
	// 	.addr_buf(addr_bufs[2]),
	// 	.sign_mask_buf(sign_mask_bufs[2]),
	// 	.word_buf(word_bufs[0]),
	// 	.write_data_buffer(write_data_buffers[2]),
	// 	.replacement_word(replacement_words[2])
	// );


	initial begin
		$readmemh("verilog/data.hex", data_block);
	end

	/*
	 *	LED register interfacing with I/O
	 */
	always @(posedge clk) begin
		if(memwrite == 1'b1 && addr == 32'h2000) begin
			led_reg <= write_data;
		end
	end

	always @(posedge clk) begin
		case(states[0]) 
			READ_BUFFER:  begin
				word_bufs[0] <= data_block[addr_bufs[0][11:2] - 32'h1000];
				if (memread_bufs[0]) begin
					states[0] <= READ;
				end
				if (memwrite_bufs[0]) begin 
					states[0] <= WRITE;
				end
			end
			READ: begin
				read_data <= read_bufs[0];
				states[0] <= IDLE;
			end

			WRITE: begin
				data_block[addr_bufs[0][11:2] - 32'h1000] <= replacement_words[0];
				states[0] <= IDLE;
			end
		endcase
		case(states[1]) 
			READ_BUFFER:  begin
				word_bufs[1] <= data_block[addr_bufs[1][11:2] - 32'h1000];
				if (memread_bufs[1]) begin
					states[1] <= READ;
				end
				if (memwrite_bufs[1]) begin 
					states[1] <= WRITE;
				end
			end
			READ: begin
				read_data <= read_bufs[1];
				states[1] <= IDLE;
			end

			WRITE: begin
				data_block[addr_bufs[1][11:2] - 32'h1000] <= replacement_words[1];
				states[1] <= IDLE;
			end
		endcase

		// case(states[2]) 
		// 	READ_BUFFER:  begin
		// 		word_bufs[2] <= data_block[addr_bufs[2][11:2] - 32'h1000];
		// 		if (memread_bufs[2]) begin
		// 			states[2] <= READ;
		// 		end
		// 		if (memwrite_bufs[2]) begin 
		// 			states[2] <= WRITE;
		// 		end
		// 	end
		// 	READ: begin
		// 		read_data <= read_bufs[2];
		// 		states[2] <= IDLE;
		// 	end

		// 	WRITE: begin
		// 		data_block[addr_bufs[2][11:2] - 32'h1000] <= replacement_words[2];
		// 		states[2] <= IDLE;
		// 	end
		// endcase

		// for (i=0; i<3; i=i+1) begin
		// 	case(states[i]) 
		// 		READ_BUFFER:  begin
		// 			word_bufs[i] <= data_block[addr_bufs[i][11:2] - 32'h1000];
		// 			if (memread_bufs[i]) begin
		// 				states[i] <= READ;
		// 			end
		// 			if (memwrite_bufs[i]) begin 
		// 				states[i] <= WRITE;
		// 			end
		// 		end
		// 		READ: begin
		// 			read_data <= read_bufs[i];
		// 			states[i] <= IDLE;
		// 		end

		// 		WRITE: begin
		// 			data_block[addr_bufs[i][11:2] - 32'h1000] <= replacement_words[i];
		// 			states[i] <= IDLE;
		// 		end
				
		// 	endcase
		// end


		if (memread | memwrite) begin 
			if (states[0] == IDLE) begin 
				memread_bufs[0] <= memread;
				memwrite_bufs[0] <= memwrite;
				write_data_buffers[0] <= write_data;
				addr_bufs[0] <= addr;
				sign_mask_bufs[0] <= sign_mask;
				states[0] <= READ_BUFFER;
			end 
			if (states[1] == IDLE) begin 
				memread_bufs[1] <= memread;
				memwrite_bufs[1] <= memwrite;
				write_data_buffers[1] <= write_data;
				addr_bufs[1] <= addr;
				sign_mask_bufs[1] <= sign_mask;
				states[1] <= READ_BUFFER;
			end 
			// else if (states[2] == IDLE) begin 
			// 	memread_bufs[2] <= memread;
			// 	memwrite_bufs[2] <= memwrite;
			// 	write_data_buffers[2] <= write_data;
			// 	addr_bufs[2] <= addr;
			// 	sign_mask_bufs[2] <= sign_mask;
			// 	states[2] <= READ_BUFFER;
			// end
		end


	end

	/*
	 *	Test led
	 */
	assign led = led_reg[7:0];
endmodule