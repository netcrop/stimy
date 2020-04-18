#include <stdio.h>
#define P1(X) (X)
int
f1 ()
{
  return 0;
}
int
f2 ()
{
  if (f1 () == 0)
    ;
    f1();
  return 0;
}
int main()
{
    int a = 0;
    P1(a) > 1;
    P1(a) <= 1;
    P1(a) != 1;
    P1(a) ==1;
    P1(a) = 1;
    P1(a) =1;
    P1(a) +=1;
    P1(a) += 1;
    P1(a) -=1;
    P1(a) *=1;
    P1(a) %=1;
    P1(a) /=1;
    P1(a) ^=1;
    P1(a) |=1;
    P1(a) <<=1;
    P1(a) >>=1;
    return 0;
}
