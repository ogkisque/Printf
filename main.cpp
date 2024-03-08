//#include <stdio.h>
extern "C" void myprintf (const char* str, ...);

int main ()
{
    const char* str1 = "format%%\n%c%c\n%c%s%%%c%c\n%s\n";
    const char str2 = 'a';
    const char str3 = 'b';
    const char str4 = 'c';
    const char* str5 = "\nSTRING\n";
    const char str6 = 'e';
    const char str7 = 'f';
    const char* str8 = "hahahoho";

    myprintf (str1, str2, str3, str4, str5, str6, str7, str8);
    return 0;
}