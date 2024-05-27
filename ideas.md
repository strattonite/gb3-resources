IDEAS FOR GAINS 

- [ ] return address prediction stack (https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) pg 16
- [ ] reduce propagation delay?
- [ ] pipelining?
- [ ] improve branch prediction?

TODO
- [ ] figure out measuring execution time / power usage 
- [ ] implement benchmarks
- [ ] program disassembler? + instruction counts

SO FAR
- lw = sw = 3 cycles
- add = addi = 1 cycle 
- all R format (arithmetic) ops are 1 cycle (sll/slti/slt may not be) 
- bubblesort constrained by sw/lw as are most alu heavy programs
- pipeline memory accesses may have best value