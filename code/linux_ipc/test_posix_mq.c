#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <mqueue.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

#define POSIX_MQ_PATH   "/test_posix_mq"
#define POSIX_MQ_PRIO   0

static int read_from_posix_mq(void)
{
    struct mq_attr attr;
    char *buf;
    ssize_t num;
    mqd_t mqid;
    int ret = 0;

    usleep(1000);

    mqid = mq_open(POSIX_MQ_PATH, O_RDONLY);
    if (mqid == -1) {
        LLOG_ERRNO("mq_open(%s) failed!\n", POSIX_MQ_PATH);
        return -1;
    }

    if (mq_getattr(mqid, &attr) == -1) {
        mq_close(mqid);
        LLOG_ERRNO("mq_getattr() failed!\n");
        return -1;
    }

    buf = malloc(attr.mq_msgsize);
    if (buf == NULL) {
        mq_close(mqid);
        LLOG_ERRNO("malloc(%ld) failed!\n", attr.mq_msgsize);
        return -1;
    }

    for (;;) {
        memset(buf, 0, attr.mq_msgsize);
        num = mq_receive(mqid, buf, attr.mq_msgsize, NULL);
        if (num == -1) {
            LLOG_ERRNO("mq_receive() failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            continue;
        if (num == 2 && buf[0] == 'q')
            break;

        TIP("mq_receive: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            ret = -1;
            break;
        }
    }
    free(buf);
    mq_close(mqid);

    return ret;
}

static int write_to_posix_mq(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    mqd_t mqid;
    int ret = 0;

    mqid = mq_open(POSIX_MQ_PATH, O_CREAT | O_EXCL | O_WRONLY,
                   S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP, NULL);
    if (mqid == -1) {
        LLOG_ERRNO("mq_open(%s) failed!\n", POSIX_MQ_PATH);
        return -1;
    }

    for (;;) {
        usleep(1000);
        TIP("mq_send: ");
        memset(buf, 0, BUF_SIZE);
        num = read(STDIN_FILENO, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read STDIN failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            continue;

        if (mq_send(mqid, buf, num, POSIX_MQ_PRIO) == -1) {
            LLOG_ERRNO("mq_send() failed!\n");
            ret = -1;
            break;
        }
        if (num == 2 && buf[0] == 'q')
            break;
    }
    mq_close(mqid);
    mq_unlink(POSIX_MQ_PATH);

    return ret;
}

int main(int argc, char *argv[])
{
    int ret = 0;

    SLOG_INFO("POSIX MQ: 父进程从终端写入获取数据发送消息，子进程接收消息将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    switch (fork()) {
        case -1:
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            ret = read_from_posix_mq();
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            ret = write_to_posix_mq();
            wait(NULL); /* wait for child process exit */
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

