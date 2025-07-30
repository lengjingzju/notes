#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

#define FIFO_PATH       "/tmp/test_fifo"

static int read_from_fifo(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int fd;
    int ret = 0;

    fd = open(FIFO_PATH, O_RDONLY);
    if (fd == -1) {
        LLOG_ERRNO("open(%s) failed!\n", FIFO_PATH);
        return -1;
    }

    for (;;) {
        memset(buf, 0, BUF_SIZE);
        num = read(fd, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read FIFO failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            break; /* End-of-file */
        if (num == 2 && buf[0] == 'q')
            break;

        TIP("read FIFO: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            ret = -1;
            break;
        }
    }
    close(fd);

    return ret;
}

static int write_to_fifo(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int fd;
    int ret = 0;

    fd = open(FIFO_PATH, O_WRONLY);
    if (fd == -1) {
        LLOG_ERRNO("open(%s) failed!\n", FIFO_PATH);
        return -1;
    }

    for (;;) {
        usleep(1000);
        TIP("write FIFO: ");
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
    close(fd);

    return ret;
}

int main(int argc, char *argv[])
{
    int ret = 0;

    SLOG_INFO("FIFO: 父进程从终端写入获取数据写入FIFO，子进程读取FIFO数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    unlink(FIFO_PATH);
    if (mkfifo(FIFO_PATH, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP) == -1 && errno != EEXIST) {
        LLOG_ERRNO("mkfifo(%s) failed!\n", FIFO_PATH);
        exit(EXIT_FAILURE);
    }

    switch (fork()) {
        case -1:
            unlink(FIFO_PATH);
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            ret = read_from_fifo();
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            ret = write_to_fifo();
            wait(NULL); /* wait for child process exit */
            unlink(FIFO_PATH);
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

