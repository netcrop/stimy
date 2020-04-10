int f0(void)
{
        if(a)
          return *x != c->x || *y != c->y || *w != c->w || *h != c->h;
        return 0;
}
struct s1{
  int a;
} this;
f1 (void)
{
  int i;

  if (sel.type == SEL_REGULAR && sel.ob.y != sel.oe.y) {
    sel.nb.x = sel.ob.y < sel.oe.y ? sel.ob.x : sel.oe.x;
    sel.ne.x = sel.ob.y < sel.oe.y ? sel.oe.x : sel.ob.x;
  } else {
    sel.nb.x = MIN(sel.ob.x, sel.oe.x);
    sel.ne.x = MAX(sel.ob.x, sel.oe.x);
  }
  sel.nb.y = MIN(sel.ob.y, sel.oe.y);
  sel.ne.y = MAX(sel.ob.y, sel.oe.y);

  selsnap(&sel.nb.x, &sel.nb.y, -1);
  selsnap(&sel.ne.x, &sel.ne.y, +1);

  /* expand selection over line breaks */
  if (sel.type == SEL_RECTANGULAR)
    return;
  i = tlinelen(sel.nb.y);
  if (i < sel.nb.x)
    sel.nb.x = i;
  if (tlinelen(sel.ne.y) <= sel.ne.x)
    sel.ne.x = term.col - 1;
}

void if_2(int *a, char *b)
{
  if (a) {
    c;
  }
  while (b) {
    {
      d;
    }
  }
}

char decl0;
int f3(void)
{
    for(int i=1;i<3;i++)
        ;
}

static char
abcf4( int *a, char *b) {
  a=1;
}

void decl1(int *a, char *b);
int f5(void)
{

}

f6(char *a, int b)
{
   a = 1;
}

int f7(char *a, int b) {
 while (a) { b = 1; }
}

int decl2(void);
if (a) {
  b;
}
char f8(int *a, char *b)
{
  a = 2;
  b = 3;
}
