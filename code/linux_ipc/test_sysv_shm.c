#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "jlog_core.h"

#define BUF_SIZE        128
#define TIP(str)        write(STDOUT_FILENO, str, strlen(str))

#define SYSV_SHM_SIZE   (8192 * 1)
#define SYSV_SEM_NUM    2

#define SYSV_SEMCTRL(idx, op)  do {     \
    sops.sem_num = idx;                 \
    sops.sem_op = op;                   \
    sops.sem_flg = 0;                   \
    semop(semid, &sops, 1);             \
} while (0)

#define SYSV_SEMWAIT(sel)  SYSV_SEMCTRL(sel, -1)
#define SYSV_SEMPOST(sel)  SYSV_SEMCTRL(sel, 1)

union semun {
    int                 val;
    struct semid_ds    *buf;
    unsigned short     *array;
#if defined(__linux__)
    struct seminfo     *__buf;
#endif
};

static int read_from_sysv_shm(int shmid, int semid)
{
    struct sembuf sops;
    char buf[BUF_SIZE];
    char *addr;
    ssize_t num;
    int bflag = 0;
    int ret = 0;

    addr = shmat(shmid, NULL, 0);
    if ((void*)addr == (void*)-1) {
        LLOG_ERRNO("shmat() failed!\n");
        return -1;
    }

    for (;;) {
        SYSV_SEMWAIT(0);
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
        SYSV_SEMPOST(1);
        if (bflag)
            break;
    }
    shmdt(addr);

    return ret;
}

static int write_to_sysv_shm(int shmid, int semid)
{
    struct sembuf sops;
    char buf[BUF_SIZE];
    char *addr;
    ssize_t num;
    int bflag = 0;
    int ret = 0;

    addr = shmat(shmid, NULL, 0);
    if ((void*)addr == (void*)-1) {
        LLOG_ERRNO("shmat() failed!\n");
        return -1;
    }

    for (;;) {
        SYSV_SEMWAIT(1);
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

        memcpy(addr, buf, BUF_SIZE);

        if (num == 2 && buf[0] == 'q') {
            bflag = 1;
        }
post:
        SYSV_SEMPOST(0);
        if (bflag)
            break;
    }
    shmdt(addr);

    return ret;
}

int main(int argc, char *argv[])
{
    union semun args[2];
    int semid;
    int shmid;
    int ret = 0;

    SLOG_INFO("SYSV SHM: 父进程从终端写入获取数据到共享内存，子进程读取共享内存将数据输出到终端。\n");
    SLOG_INFO("[input q to exit]\n");

    shmid = shmget(IPC_PRIVATE, SYSV_SHM_SIZE, IPC_CREAT | IPC_EXCL
                   | S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (shmid == -1) {
        LLOG_ERRNO("shmget() failed!\n");
        exit(EXIT_FAILURE);
    }

    semid = semget(IPC_PRIVATE, SYSV_SEM_NUM, IPC_CREAT | IPC_EXCL
                   | S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    if (semid == -1) {
        shmctl(shmid, IPC_RMID, 0);
        LLOG_ERRNO("semget() failed!\n");
        exit(EXIT_FAILURE);
    }

    args[0].val = 0;
    args[1].val = 1;
    if (semctl(semid, 0, SETVAL, args[0]) == -1
            || semctl(semid, 1, SETVAL, args[1]) == -1) {
        semctl(semid, 0, IPC_RMID);
        semctl(semid, 1, IPC_RMID);
        shmctl(shmid, IPC_RMID, NULL);
        LLOG_ERRNO("semctl() failed!\n");
        exit(EXIT_FAILURE);
    }

    switch (fork()) {
        case -1:
            semctl(semid, 0, IPC_RMID);
            semctl(semid, 1, IPC_RMID);
            shmctl(shmid, IPC_RMID, NULL);
            LLOG_ERRNO("fork() failed!\n");
            exit(EXIT_FAILURE);

        case 0: /* Child */
            ret = read_from_sysv_shm(shmid, semid);
            SLOG_INFO("child process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            ret = write_to_sysv_shm(shmid, semid);
            wait(NULL); /* wait for child process exit */
            semctl(semid, 0, IPC_RMID);
            semctl(semid, 1, IPC_RMID);
            shmctl(shmid, IPC_RMID, NULL);
            SLOG_INFO("parent process exit!\n");
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }
}

