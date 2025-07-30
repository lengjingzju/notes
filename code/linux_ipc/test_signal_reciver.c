#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include "jlog_core.h"

void sighandler(int signo, siginfo_t *info, void *ctx)
{
    /* info->si_int 和 info->si_value.sival_int 的 value 是一样的 */
    SLOG_INFO("receive signal %d and value %d.\n", signo, info->si_int);
}

int main(void)
{
    struct sigaction act;

    sigemptyset(&act.sa_mask);
    act.sa_flags = SA_SIGINFO; // 选择信号处理函数为 sa_sigaction, 否则选择 sa_handler
    act.sa_sigaction = sighandler;
    if (sigaction(SIGINT, &act, NULL) == -1) {
        LLOG_ERROR("sigaction() failed!\n");
        exit(EXIT_FAILURE);
    }

    for (;;) {
        SLOG_INFO("process %d waiting a signal ...\n", (int)getpid());
        pause();
    }

    exit(EXIT_FAILURE);
}

