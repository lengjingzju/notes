#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

static int read_from_pipe(int fd)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int ret = 0;

    for (;;) {
        memset(buf, 0, BUF_SIZE);
        num = read(fd, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read PIPE failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            break; /* End-of-file */
        if (num == 2 && buf[0] == 'q')
            break;

        TIP("read PIPE: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            ret = -1;
            break;
        }
    }

    return ret;
}

static int write_to_pipe(int fd)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int ret = 0;

    for (;;) {
        usleep(1000);
        TIP("write PIPE: ");
        memset(buf, 0, BUF_SIZE);
        num = read(STDIN_FILENO, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read STDIN failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            continue;

        if (write(fd, buf, num) != num) {
            LLOG_ERRNO("write FIFO failed!\n");
            ret = -1;
            break;
        }
        if (num == 2 && buf[0] == 'q')
            break;
    }

    return ret;
}

int main(int argc, char *argv[])
{
    int pfd[2];
    int ret = 0;

    SLOG_INFO("PIPE: 父进程从终端写入获取数据，通过管道传递给子进程，子进程再将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    if (pipe(pfd) == -1) {
        LLOG_ERRNO("pipe() failed!\n");
        exit(EXIT_FAILURE);
    }

    switch (fork()) {
        case -1:
            close(pfd[0]);
            close(pfd[1]);
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            close(pfd[1]);     /* Close unused write end */
            ret = read_from_pipe(pfd[0]);
            close(pfd[0]);
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            close(pfd[0]);     /* Close unused read end */
            ret = write_to_pipe(pfd[1]);
            close(pfd[1]);
            wait(NULL); /* wait for child process exit */
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

