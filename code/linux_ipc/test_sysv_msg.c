#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/msg.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

#define SYSV_MSG_TYPE   1
#define SYSV_MSG_PATH   "/tmp/test_sysv_msg"
#define SYSV_MSG_PROJ   123

struct mbuf {
    long mtype;
    char mtext[BUF_SIZE];
};

static int read_from_sysv_msg(void)
{
    struct mbuf msg;
    key_t key;
    int msgid;
    ssize_t num;
    int ret = 0;

    usleep(1000);

    key = ftok(SYSV_MSG_PATH, SYSV_MSG_PROJ);
    msgid = msgget(key, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (msgid == -1) {
        LLOG_ERRNO("msgget(%s) failed!\n", SYSV_MSG_PATH);
        return -1;
    }

    for (;;) {
        memset(msg.mtext, 0, BUF_SIZE);
        num = msgrcv(msgid, &msg, BUF_SIZE, SYSV_MSG_TYPE, 0);
        if (num == -1) {
            LLOG_ERRNO("msgrcv() failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            continue;
        if (num == 2 && msg.mtext[0] == 'q')
            break;

        TIP("msgrcv: ");
        if (write(STDOUT_FILENO, msg.mtext, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            ret = -1;
            break;
        }
    }

    return ret;
}

static int write_to_sysv_msg(void)
{
    struct mbuf msg;
    key_t key;
    int msgid;
    ssize_t num;
    int ret = 0;

    key = ftok(SYSV_MSG_PATH, SYSV_MSG_PROJ);
    msgid = msgget(key, IPC_CREAT | IPC_EXCL | S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (msgid == -1) {
        LLOG_ERRNO("msgget(%s) failed!\n", SYSV_MSG_PATH);
        return -1;
    }

    msg.mtype = SYSV_MSG_TYPE;
    for (;;) {
        usleep(1000);
        TIP("msgsnd: ");
        memset(msg.mtext, 0, BUF_SIZE);
        num = read(STDIN_FILENO, msg.mtext, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read STDIN failed!\n");
            ret = -1;
            break;
        }
        if (num == 0)
            continue;

        if (msgsnd(msgid, &msg, num, 0) == -1) {
            LLOG_ERRNO("msgsnd() failed!\n");
            ret = -1;
            break;
        }
        if (num == 2 && msg.mtext[0] == 'q')
            break;
    }
    msgctl(msgid, IPC_RMID, 0);

    return ret;
}

int main(int argc, char *argv[])
{
    int ret = 0;

    SLOG_INFO("SYSV MSG: 父进程从终端写入获取数据发送消息，子进程接收消息将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    switch (fork()) {
        case -1:
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            ret = read_from_sysv_msg();
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            ret = write_to_sysv_msg();
            wait(NULL); /* wait for child process exit */
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

