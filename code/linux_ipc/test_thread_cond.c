#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/stat.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

static char addr[BUF_SIZE];
static int flag = 0;
static pthread_mutex_t mtx;
static pthread_cond_t cond;

static int read_from_global_buf(void)
{
    char buf[BUF_SIZE];
    ssize_t num;
    int bflag = 0;
    int ret = 0;

    for (;;) {
        pthread_mutex_lock(&mtx);
        while (!flag)
            pthread_cond_wait(&cond, &mtx);
        memset(buf, 0, BUF_SIZE);
        memcpy(buf, addr, BUF_SIZE);
        num = strlen(buf);
        if (num == 0) {
            goto unlock;
        }
        if (num == 2 && buf[0] == 'q') {
            bflag = 1;
            goto unlock;
        }

        TIP("read buf: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            bflag = 1;
            ret = -1;
        }
unlock:
        flag = 0;
        pthread_mutex_unlock(&mtx);
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
        usleep(1000);
        pthread_mutex_lock(&mtx);
        TIP("write buf: ");
        memset(buf, 0, BUF_SIZE);
        num = read(STDIN_FILENO, buf, BUF_SIZE);
        if (num == -1) {
            LLOG_ERRNO("read STDIN failed!\n");
            bflag = 1;
            ret = -1;
            goto unlock;
        }
        if (num == 0) {
            goto unlock;
        }

        memset(addr, 0, BUF_SIZE);
        memcpy(addr, buf, BUF_SIZE);
        if (num == 2 && buf[0] == 'q') {
            bflag = 1;
        }
unlock:
        flag = 1;
        pthread_mutex_unlock(&mtx);
        pthread_cond_signal(&cond);
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

    SLOG_INFO("pthread_cond: 主线程从终端写入获取数据到全局变量，子线程读取全局变量将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    if (pthread_mutex_init(&mtx, NULL) != 0) {
        LLOG_ERRNO("pthread_mutex_init() failed!\n");
        exit(EXIT_FAILURE);
    }

    if (pthread_cond_init(&cond, NULL) != 0) {
        pthread_mutex_destroy(&mtx);
        LLOG_ERRNO("pthread_cond_init() failed!\n");
        exit(EXIT_FAILURE);
    }

    if (pthread_create(&tid, NULL, thread_handler, NULL) != 0) {
        pthread_cond_destroy(&cond);
        pthread_mutex_destroy(&mtx);
        LLOG_ERRNO("pthread_create() failed!\n");
        exit(EXIT_FAILURE);
    }

    write_to_global_buf();

    pthread_join(tid, NULL);
    pthread_cond_destroy(&cond);
    pthread_mutex_destroy(&mtx);

    SLOG_INFO("parent thread exit!\n");
    exit(EXIT_SUCCESS);
}

