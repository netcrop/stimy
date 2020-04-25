/* comment
 */ # define PREP(X) (X)
# define condition(X) \
    (fprintf(stdout,"%s\n","condition") ? (X) : (X))
 #
int preprocessor()
{
    return 1;
}
int preprocessor2()
{
    int a = 2;
    if(condition(PREP(a)) >= 1);
    if(condition(preprocessor(a)) >= 1);
    if(condition(PREP(a)) >> 1);
    if(condition(preprocessor(a)) >= 1);
    if(condition(PREP(a)) + 1);
    if(condition(preprocessor(a)) + 1);
    if(condition(PREP(a)) += 1);
    return a;
}
