#define SPIN_CYCLES 3000000

int main(void)
{
    volatile unsigned int *gDebugLedsMemoryMappedRegister = (unsigned int *)0x2000;

    int a = 0;
    int b = 0;

    *gDebugLedsMemoryMappedRegister = 0x00;
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;

    *gDebugLedsMemoryMappedRegister = 0xFF;
    // measure cycles for spin loop alone
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
        b += a; // add
    }

    *gDebugLedsMemoryMappedRegister = 0x00;
    for (int j = 0; j < SPIN_CYCLES; j++)
        ;
}