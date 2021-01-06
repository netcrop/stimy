#define stimy_print(X,Y) if (printf("%s\n",#X)) Y
#define stimy_echo(X,Y) (printf("%s\n",#X) ? (Y) : (Y) )
#define f3() if(1) f2()
int f1()
{
    return 1;
}
int f2()
{
    printf("%s\n","f2");
    return 1;
}
int f()
{
    stimy_print(f3,f3());
    int a = stimy_echo(f2,f2());
    return a;
}
