#include<unistd.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<sys/wait.h>
#define MAXLINE 2048

int main() {
    while (1) {
        int pipe_fd[2];
        pipe(pipe_fd);
        printf("myshell:~$");
        char buf[MAXLINE];
        char *com[MAXLINE];
        char *arg[MAXLINE];
        int index = 0;
        fgets(buf, MAXLINE, stdin);
        if (buf[strlen(buf)-1] == '\n')
            buf[strlen(buf)-1] = '\0';
        com[index++] = strtok(buf, "|");
        while ((com[index++] = strtok(NULL, "|")));
        com[index-1] = 0;
        int comCount = 0;
        if (index == 2) {
            int i = 0;
            arg[i++] = strtok(com[0], " ");
            while ((arg[i++] = strtok(NULL, " ")));
            arg[i-1] = 0;
            int cpid;
            if ((cpid = fork()) == 0) {
                execvp(arg[0], arg);
                perror("command not found");
                exit(1);
            }
            int pid;
            while ((pid = wait(NULL)) != -1);
        }
        else {
            while (index - comCount >= 2) {
                int i = 0;
                arg[i++] = strtok(com[comCount], " ");
                while ((arg[i++] = strtok(NULL, " ")));
                arg[i-1] = 0;
                int cpid;
                if (index - comCount == 2) {
                    if ((cpid = fork()) == 0) {
                        close(pipe_fd[1]);
                        close(fileno (stdin));
                        dup2(pipe_fd[0], fileno(stdin));
                        close (pipe_fd[0]);
                        execvp(arg[0], arg);
                        perror("command not found");
                        exit(1);
                    }
                } else if (comCount == 0) {
                    if ((cpid = fork()) == 0) {
                        close(pipe_fd[0]);
                        close(fileno(stdout));
                        dup2(pipe_fd[1], fileno(stdout));
                        close(pipe_fd[1]);
                        execvp(arg[0], arg);
                        perror("command not found");
                        exit(1);
                    }
                } else {
                    if ((cpid = fork()) == 0) {
                        close(fileno (stdin));
                        dup2(pipe_fd[0], fileno(stdin));
                        close (pipe_fd[0]);
                        close(fileno(stdout));
                        dup2(pipe_fd[1], fileno(stdout));
                        close(pipe_fd[1]);
                        execvp(arg[0], arg);
                        perror("command not found");
                        exit(1);
                    }
                }
                int pid;
                while ((pid = wait(NULL)) != -1);
                comCount++;
            }
        }
    }
}
