include config.mk

SRC = stimy.c
OBJ = ${SRC:.c=.o}

all: options stimy

options:
	@echo stimy build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.mk

stimy: ${OBJ}
	${CC} -g3 -o $@ ${OBJ} ${LDFLAGS}

.PHONY: all options
