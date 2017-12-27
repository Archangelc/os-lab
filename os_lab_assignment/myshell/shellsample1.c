#include <stdio.h>
#define MASKVALH 0x0000FF00
#define MASKVALL 0x000000FF
#define HBYTE(x) ((x & MASKVALH) >> 8)
#define LBYTE(x) (x & MASKVALL)
main() 
{
    int p1, p2, status, childpid;
    // setbuf(stdout, NULL);
    while ((p1 = fork()) == -1);
    if (p1 == 0)
    {
        printf("child(1) pid=%d\n", getpid());
        exit(1);
    }
    else
    {
        while ((p2 = fork()) == -1);
        if (p2 == 0)
        {
            print("child(2) pid=%d\n", getpid());
        } 
        else 
        {
            sleep(2);
            printf("parent pid=%d\n", getpid());
            while((childpid = wait(&status)) != -1)
                if (LBYTE(status) == 0)
                    printf("wait child(pid=%d) exitcode=%d\n", childpid, HBYTE(status));
        }
    }
}