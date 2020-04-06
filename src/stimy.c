#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#ifndef STIMY_H
#include <stimy.h>
#endif
void stimy_mlocate(void **p, size_t size)
{
    if ((*p = malloc(size)))
        return;
   fprintf(stdout, "%s %s\n",__func__,":failed.");
   exit(0);
}
void stimy_delocate(void)
{
    if (!pstimy)
        return;
if (stimy.pfilestat)
        free(stimy.pfilestat);
if (stimy.fp)
        fclose(stimy.fp);
    free(pstimy);
    pstimy = NULL;
}
extern void stimy_checkfile(void)
{
    if(!pstimy)
        return;
    if (stat(stimy.filename, stimy.pfilestat) == EXIST)
        return;
    if((stimy.fp = fopen(stimy.filename, "a+")))
        return;
    fprintf(stdout, "%s %s\n",__func__,":fopen:failed.");
    exit(0);
}
extern void stimy_alocate(void)
{
    if(pstimy)
        return;
    atexit(stimy_delocate);
    stimy_mlocate((void **)&pstimy, sizeof(stimy_t));
    stimy_mlocate((void **)&pstimy->pfilestat, sizeof(struct stat));
    strcpy(stimy.filename, "/tmp/stimy0.txt");
    stimy.counter = 0;
    stimy.fp = NULL;
    for (int i = 0; i < STIMYINSTANS; i++) {
        stimy.filename[10] = i + '0';
        if (stat(stimy.filename, stimy.pfilestat) == EXIST)
            continue;
        i = STIMYINSTANS;
    }
    for (int i = 0; i < SPACEPADD; i++)
        stimy.space[i] = ' ';
    for (int i = SPACEPADD; i < SPACESIZE; i++)
        stimy.space[i] = '\0';
    stimy.index = SPACEPADD;
    if((stimy.fp = fopen(stimy.filename, "a+")))
        return;
    fprintf(stdout, "%s %s\n",__func__,":fopen:failed.");
    exit(0);
}
