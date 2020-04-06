include config.mk

SRC = verify.c
OBJ = ${SRC:.c=.o}

all: options verify

options:
	@echo verify build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.mk

verify: ${OBJ}
	${CC} -g3 -o $@ ${OBJ} ${LDFLAGS}
clean:
	rm -f *.o verify

.PHONY: all options
