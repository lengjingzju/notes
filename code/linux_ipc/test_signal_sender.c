#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include "jlog_core.h"

int main(int argc, char **argv)
{
    union sigval val;
    pid_t pid;
    int num;

    if (argc != 3) {
        SLOG_ERROR("usage: %s <pid> <num>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    pid = atoi(argv[1]);
    num = atoi(argv[2]);
    SLOG_INFO("sending signal %d and value %d to process %d ...\n", SIGINT, num, pid);
    val.sival_int = num;
    if (sigqueue(pid, SIGINT, val) == -1) {
        LLOG_ERROR("sigqueue signal %d to process %d failed!\n", SIGINT, pid);
        exit(EXIT_FAILURE);
    }

    exit(EXIT_SUCCESS);
}

