#ifndef STIMY_H
#define STIMY_H 1
#endif
#ifndef _THREADS_H
#include <threads.h>
#endif
#ifndef _STDATOMIC_H
#include <stdatomic.h>
#endif
#ifndef _STDIO_H
#include <stdio.h>
#endif
#define stimy_echo(X,Y) \
    (fprintf(stimy.fp,"%8d %4d %s %s\n",\
    stimy.counter++,stimy.index,stimy.space,#X) ? (Y) : (Y))

#define stimy_emit(N) \
do{\
    stimy_alocate();\
    stimy_checkfile();\
    if(N){\
        fprintf(stimy.fp,"%8d %4d %s %s %d\n",\
        stimy.counter++,stimy.index,stimy.space,__func__,N);\
        if (stimy.index < 2) stimy.index = 2;\
        stimy.space[--stimy.index] = '\0';\
        stimy.space[--stimy.index] = '\0';\
    }else{\
        stimy.space[stimy.index++] = ' ';\
        stimy.space[stimy.index++] = ' ';\
            fprintf(stimy.fp,"%8d %4d %s %s %d\n",\
            stimy.counter++,stimy.index,stimy.space,__func__,N);\
    }\
} while(0)
#define stimy_pre() stimy_emit(0);
#define stimy_post(X) do { stimy_emit(1); return X; } while(0)
enum
{ EXIST = 0, STIMYINSTANS = 9, FILENAMESIZE = 16, SPACEPADD =
    4, SPACESIZE = 80
};
typedef struct stimy_t stimy_t;
struct stimy_t
{
  FILE *fp;
  char filename[FILENAMESIZE];
  atomic_int counter;
  atomic_char space[SPACESIZE];
  atomic_int index;
  struct stat *pfilestat;
};
void stimy_mlocate (void **, size_t);
void stimy_delocate (void);
extern void stimy_alocate (void);
extern void stimy_checkfile (void);
stimy_t *pstimy;
#define stimy (*pstimy)
