############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

PACKAGE_NAME    = ipc-examples
CPFLAGS        += -Wno-unused-result -Wno-unused-parameter

.PHONY: all clean install
all:
	@echo "Build $(PACKAGE_NAME) Done!"

INC_MAKES      := app
include inc.makes

$(eval $(call add-bin-build,test_fifo,test_fifo.c))
$(eval $(call add-bin-build,test_pipe,test_pipe.c))
$(eval $(call add-bin-build,test_sysv_msg,test_sysv_msg.c))
$(eval $(call add-bin-build,test_posix_mq,test_posix_mq.c,-lrt))
$(eval $(call add-bin-build,test_sysv_shm,test_sysv_shm.c))
$(eval $(call add-bin-build,test_posix_shm,test_posix_shm.c,-lrt -pthread))
$(eval $(call add-bin-build,test_thread_sem,test_thread_sem.c,-pthread))
$(eval $(call add-bin-build,test_thread_cond,test_thread_cond.c,-pthread))
$(eval $(call add-bin-build,test_signal_sender,test_signal_sender.c))
$(eval $(call add-bin-build,test_signal_reciver,test_signal_reciver.c))

all: $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_bins
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done!"
