extern "C" void myprintf (const char* str, ...);

int main ()
{
    const char* format = "%o\n%b\n%c\n%s\n%%\n%x\n%c\n%d\n";
    long long   par1 = 07654321;
    long long   par2 = -5;
    const char  par3 = 'c';
    const char* par4 = "STRING";
    long long   par5 = 0xA1B2C3DEF;
    const char  par6 = 'f';
    long long   par7 = -123456789;

    myprintf (format, par1, par2, par3, par4, par5, par6, par7);
    return 0;
}