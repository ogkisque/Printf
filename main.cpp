//#include <stdio.h>
extern "C" void myprintf (const char* str, ...);

int main ()
{
    const char* str1 = "str1\n";
    const char* str2 = "str2\n";
    const char* str3 = "str3\n";
    const char* str4 = "str4\n";
    const char* str5 = "str5\n";
    const char* str6 = "str6\n";
    const char* str7 = "str7\n";
    const char* str8 = "str8\n";

    myprintf (str1, str2, str3, str4, str5, str6, str7, str8);
    return 0;
}