
int main(void)
{
	/*
	 *	Reading from the special address pointed to by
	 *	gDebugLedsMemoryMappedRegister will cause the processor to
	 *	set the value of 8 of the FPGA's pins to the byte written
	 *	to the address. See the PCF file for how those 8 pins are
	 *	mapped.
	 */
	enum
	{
		kSpinDelay = 400000,
	};
	
	int a = 0b1010;
	int b = 0b0001;
	int c = 0b1001;
	int result = a-b;
	
	volatile unsigned int *gDebugLedsMemoryMappedRegister = (unsigned int *)0x2000;
	*gDebugLedsMemoryMappedRegister = 0x00;
	while (1)
	{
		if (result==c) 
		*gDebugLedsMemoryMappedRegister = 0xFF;

		/*
		 *	Spin
		 */
		for (int j = 0; j < kSpinDelay; j++)
			;

		*gDebugLedsMemoryMappedRegister = 0x00;

		/*
		 *	Spin
		 */
		for (int j = 0; j < kSpinDelay; j++)
			;
	}
}
