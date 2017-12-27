CC=gcc
EXE=myshell

all:${EXE}

myshell:myshell.o
	${CC} -o $@ $<

myshell.o:myshell.c
	${CC} -c $<

run:${EXE}
	./myshell

clean:
	rm -fr ${EXE} *.o
