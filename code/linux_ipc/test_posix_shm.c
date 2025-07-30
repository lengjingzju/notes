#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <semaphore.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

#define POSIX_SHM_SIZE  (8192 * 1)
#define POSIX_SHM_PATH  "/test_posix_shm"
#define POSIX_RSEM_PATH "/test_posix_rsem"
#define POSIX_WSEM_PATH "/test_posix_wsem"

static int read_from_posix_shm(void)
{
    char buf[BUF_SIZE];
    char *addr;
    ssize_t num;
    int shmid;
    sem_t *rsemid, *wsemid;
    int bflag = 0;
    int ret = 0;

    usleep(1000);

    shmid = shm_open(POSIX_SHM_PATH, O_RDWR, 0);
    if (shmid == -1) {
        LLOG_ERRNO("shm_open(%s) failed!\n", POSIX_SHM_PATH);
        ret = -1;
        goto end0;
    }

    addr = mmap(NULL, POSIX_SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shmid, 0);
    if ((void*)addr == MAP_FAILED) {
        LLOG_ERRNO("mmap(%s) failed!\n", POSIX_SHM_PATH);
        ret = -1;
        goto end1;
    }

    rsemid = sem_open(POSIX_RSEM_PATH, O_RDWR);
    if ((void*)rsemid == (void*)-1) {
        LLOG_ERRNO("sem_open(%s) failed!\n", POSIX_RSEM_PATH);
        ret = -1;
        goto end2;
    }

    wsemid = sem_open(POSIX_WSEM_PATH, O_RDWR);
    if ((void*)wsemid == (void*)-1) {
        LLOG_ERRNO("sem_open(%s) failed!\n", POSIX_WSEM_PATH);
        ret = -1;
        goto end3;
    }

    for (;;) {
        sem_wait(rsemid);
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

        TIP("read SHM: ");
        if (write(STDOUT_FILENO, buf, num) != num) {
            LLOG_ERRNO("write STDOUT failed!\n");
            bflag = 1;
            ret = -1;
        }
post:
        sem_post(wsemid);
        if (bflag)
            break;
    }

    sem_close(wsemid);
end3:
    sem_close(rsemid);
end2:
    munmap(addr, POSIX_SHM_SIZE);
end1:
    close(shmid);
end0:
    return ret;
}

static int write_to_posix_shm(void)
{
    char buf[BUF_SIZE];
    char *addr;
    ssize_t num;
    int shmid;
    sem_t *rsemid, *wsemid;
    int bflag = 0;
    int ret = 0;

    shmid = shm_open(POSIX_SHM_PATH, O_CREAT | O_EXCL | O_RDWR,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (shmid == -1) {
        LLOG_ERRNO("shm_open(%s) failed!\n", POSIX_SHM_PATH);
        ret = -1;
        goto end0;
    }

    if (ftruncate(shmid, POSIX_SHM_SIZE) == -1) {
        LLOG_ERRNO("ftruncate(%d) failed!\n", POSIX_SHM_SIZE);
        ret = -1;
        goto end1;
    }

    addr = mmap(NULL, POSIX_SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shmid, 0);
    if ((void*)addr == MAP_FAILED) {
        LLOG_ERRNO("mmap(%s) failed!\n", POSIX_SHM_PATH);
        ret = -1;
        goto end1;
    }

    rsemid = sem_open(POSIX_RSEM_PATH, O_CREAT | O_EXCL | O_RDWR,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP, 0);
    if ((void*)rsemid == (void*)-1) {
        LLOG_ERRNO("sem_open(%s) failed!\n", POSIX_RSEM_PATH);
        ret = -1;
        goto end2;
    }

    wsemid = sem_open(POSIX_WSEM_PATH, O_CREAT | O_EXCL | O_RDWR,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP, 1);
    if ((void*)wsemid == (void*)-1) {
        LLOG_ERRNO("sem_open(%s) failed!\n", POSIX_WSEM_PATH);
        ret = -1;
        goto end3;
    }

    for (;;) {
        sem_wait(wsemid);
        TIP("write SHM: ");
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
        sem_post(rsemid);
        if (bflag)
            break;
    }

    sem_close(wsemid);
    sem_unlink(POSIX_WSEM_PATH);
end3:
    sem_close(rsemid);
    sem_unlink(POSIX_RSEM_PATH);
end2:
    munmap(addr, POSIX_SHM_SIZE);
end1:
    close(shmid);
    shm_unlink(POSIX_SHM_PATH);
end0:
    return ret;
}

int main(int argc, char *argv[])
{
    int ret = 0;

    SLOG_INFO("POSIX SHM: 父进程从终端写入获取数据发送消息，子进程接收消息将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    switch (fork()) {
        case -1:
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            ret = read_from_posix_shm();
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            ret = write_to_posix_shm();
            wait(NULL); /* wait for child process exit */
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

