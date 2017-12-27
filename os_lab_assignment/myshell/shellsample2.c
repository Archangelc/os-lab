#include <stdio.h>
main() 
{
    int cpid1, cpid2, pid, status;
    setbuf(stdout, NULL);
    if ((cpid1 = fork()) == 0)
    {
        execlp("echo", "echo", "I amd child 1", (char*)0);
        puts("hello in child1");
        perror("execl_1")
        exit(1);
    }
    if ((cpid2 = fork()) == 0)
    {
        execlp("date", "date", (char*)0);
        perror("execl_2");
        exit(2);
    }
    puts("Parent process waiting for children");
    while((pid = wait(&status)) != -1)
        if (cpid1 == pid)
            printf("child 1 terminated with status %d\n", (status >> 8));
        else if (cpid2 == pid)
            printf("child 2 terminated with status %d\n", (status >> 8));
    puts("All children terminated!");
    puts("Parent process terminated now!");
    exit(0);
}