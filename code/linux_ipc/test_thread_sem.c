#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <semaphore.h>
#include <pthread.h>
#include <sys/stat.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

static char addr[BUF_SIZE];
static sem_t rsem, wsem;

static int read_from_global_buf(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int bflag = 0;
    int ret = 0;

    for (;;) {
        sem_wait(&rsem);
        memset(buf, 0, BUF_SIZE);
        memcpy(buf, addr, BUF_SIZE);
        num = strlen(buf);
        if (num == 0) {
            goto post;
        }
        if (num == 2 && buf[0] == 'q') {
            bflag = 1;
            goto post;
        }

        TIP("read buf: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            bflag = 1;
            ret = -1;
        }
post:
        sem_post(&wsem);
        if (bflag)
            break;
    }

    return ret;
}

static int write_to_global_buf(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int bflag = 0;
    int ret = 0;

    for (;;) {
        sem_wait(&wsem);
        TIP("write buf: ");
        memset(buf, 0, BUF_SIZE);
        num = read(STDIN_FILENO, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read STDIN failed!\n");
            bflag = 1;
            ret = -1;
            goto post;
        }
        if (num == 0) {
            goto post;
        }

        memset(addr, 0, BUF_SIZE);
        memcpy(addr, buf, BUF_SIZE);
        if (num == 2 && buf[0] == 'q') {
            bflag = 1;
        }
post:
        sem_post(&rsem);
        if (bflag)
            break;
    }

    return ret;
}

static void* thread_handler(void *arg)
{
    int ret = read_from_global_buf();
    SLOG_INFO("child thread exit!\n");
    pthread_exit(ret == 0 ? (void*)0 : (void*)-1);
}

int main(int argc, char *argv[])
{
    pthread_t tid;

    SLOG_INFO("pthread sem: 主线程从终端写入获取数据到全局变量，子线程读取全局变量将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    if (sem_init(&rsem, 0, 0) == -1) {
        LLOG_ERRNO("sem_init() failed!\n");
        exit(EXIT_FAILURE);
    }

    if (sem_init(&wsem, 0, 1) == -1) {
        sem_destroy(&rsem);
        LLOG_ERRNO("sem_init() failed!\n");
        exit(EXIT_FAILURE);
    }

    if (pthread_create(&tid, NULL, thread_handler, NULL) != 0) {
        sem_destroy(&wsem);
        sem_destroy(&rsem);
        LLOG_ERRNO("pthread_create() failed!\n");
        exit(EXIT_FAILURE);
    }

    write_to_global_buf();

    pthread_join(tid, NULL);
    sem_destroy(&wsem);
    sem_destroy(&rsem);

    SLOG_INFO("parent thread exit!\n");
    exit(EXIT_SUCCESS);
}

