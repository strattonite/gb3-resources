
#define SPIN_CYCLES 3000000

// we assume add/sub are same, likewise OR/XOR/AND, <</>>

int main(void)
{
    volatile unsigned int *gDebugLedsMemoryMappedRegister = (unsigned int *)0x2000;

    int a = 0;
    int b = 0;
    int c = 0;
    int d = 0;

    *gDebugLedsMemoryMappedRegister = 0x00;
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;

    *gDebugLedsMemoryMappedRegister = 0xFF;
    // measure cycles for j++
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;

    *gDebugLedsMemoryMappedRegister = 0x00;
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;

    *gDebugLedsMemoryMappedRegister = 0xFF;
    for (int j = 0; j < SPIN_CYCLES; j++)
    {
        a += 274; // addi
    }

    *gDebugLedsMemoryMappedRegister = 0x00;
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;

    *gDebugLedsMemoryMappedRegister = 0xFF;
    for (int j = 0; j < SPIN_CYCLES; j++)
    {
        d += a; // add
        c = d;
    }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b += a; // add
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = b ^ 0xfa; // xori
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = b ^ a; // xor
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = b << 3; // slli
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // int x = (b ^ a) & 0xf;
    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = b << x; // sll
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = a < 0xf1; // slti
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;

    // *gDebugLedsMemoryMappedRegister = 0xFF;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    // {
    //     b = a < x; // slt
    // }

    // *gDebugLedsMemoryMappedRegister = 0x00;
    // for (int j = 0; j < SPIN_CYCLES; j++)
    //     ;
}