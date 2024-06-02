

/*
 *	top.v
 *
 *	Top level entity, linking cpu with data and instruction memory.
 */

module top (led);
	output [7:0]	led;
	//input		clk_input;
	wire		clk_proc;
	wire		data_clk_stall;
	wire		clk;
	//wire        high_clk; 
	reg		ENCLKHF		= 1'b1;	// Plock enable
	//reg		ENCLKLF		= 1'b1;	// Plock enable
	reg		CLKHF_POWERUP	= 1'b1;	// Power up the HFOSC circuit
	//reg		CLKLF_POWERUP	= 1'b1;	// Power up the LFOSC circuit
	//reg     clk_divided = 0;
	//reg [1:0] counter = 0;

	/*
	 *	Use the iCE40's hard primitive for the clock source.
	 */
	// set the clock frequency to 12 MHz 

	
	//6MHz
	SB_HFOSC #(.CLKHF_DIV("0b11")) OSCInst0 (
		.CLKHFEN(ENCLKHF),
		.CLKHFPU(CLKHF_POWERUP),
		.CLKHF(clk)
	);
	/*
	flipflopclk flipflopclk_inst(
        .hf_clk(high_clk),
        .clk(clk) // 1.5 MHz
    );
	*/

	/*
	SB_LFOSC OSCInst1 (
		.CLKLFEN(ENCLKLF),
		.CLKLFPU(CLKLF_POWERUP),
		.CLKLF(clk)
	);
	*/
	
	/*
	always @(posedge high_clk) begin
		if (counter == 2'b11) begin 
			clk_divided <= ~clk_divided;
			counter <= 0;
		end
		else begin
			counter <= counter + 1;
		end
	end

	assign clk = clk_divided;
	*/

	// Use PLL instead
	/*
	pll pll_inst(
			.clock_in(clk_input),
			.clock_out(clk)
	);
	*/

	/*
	 *	Memory interface
	 */
	wire[31:0]	inst_in;
	wire[31:0]	inst_out;
	wire[31:0]	data_out;
	wire[31:0]	data_addr;
	wire[31:0]	data_WrData;
	wire		data_memwrite;
	wire		data_memread;
	wire[3:0]	data_sign_mask;


	cpu processor(
		.clk(clk_proc),
		.inst_mem_in(inst_in),
		.inst_mem_out(inst_out),
		.data_mem_out(data_out),
		.data_mem_addr(data_addr),
		.data_mem_WrData(data_WrData),
		.data_mem_memwrite(data_memwrite),
		.data_mem_memread(data_memread),
		.data_mem_sign_mask(data_sign_mask)
	);

	instruction_memory inst_mem( 
		.addr(inst_in), 
		.out(inst_out)
	);

	data_mem data_mem_inst(
			.clk(clk),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite), 
			.memread(data_memread), 
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led(led),
			.clk_stall(data_clk_stall)
		);

	assign clk_proc = (data_clk_stall) ? 1'b1 : clk;
endmodule
