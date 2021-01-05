int f1(int a)
{
    return a;
}
int f()
{
    int data;
    if(!(data = f1(1)) || !(data = f1(f1(2))))
        return 2;
    return 0;
}
