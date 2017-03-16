PROJECT	:= cuda-nvme
OBJECTS := userspace/cunvme.c.o userspace/nvme_init.c.o userspace/page.cu.o userspace/nvme_core.cu.o userspace/nvme_queue.c.o userspace/cuda.cu.o
RELEASE := $(shell uname -r)
CUHOME	:= /usr/local/cuda
MODULE	:= cunvme
DEFINES	:= -DCUNVME_FILE='"$(MODULE)"' -DCUNVME_VERSION='"0.1"' -DMAX_DBL_MEM=0x256
NVDRIVE := 367.48


obj-m := $(MODULE).o
$(MODULE)-objs := module/cunvme.o
ccflags-y += -I$(PWD)/include $(DEFINES) -I/usr/src/nvidia-$(NVDRIVE)/
KDIR ?= /lib/modules/$(RELEASE)/build
KBUILD_EXTRA_SYMBOLS := /usr/src/nvidia-$(NVDRIVE)/Module.symvers

ifeq ($(KERNELRELEASE),)
	CC    	:= $(CUHOME)/bin/nvcc
	CCBIN	:= /usr/bin/gcc
	CFLAGS	:= -Wall -Wextra -O0 -Werror=missing-declarations -Werror=missing-prototypes -Werror=implicit-function-declaration
	INCLUDE	:= -I$(CUHOME)/include -Iinclude -DCUNVME_PATH='"/proc/$(MODULE)"'
	LDLIBS	:= -lcuda -lc
	LDFLAGS	:= -L$(CUHOME)/lib64
endif


.PHONY: default reload unload load

default: modules $(PROJECT)

clean:
	-$(RM) $(PROJECT) $(OBJECTS)
	$(MAKE) -C $(KDIR) M=$(PWD) clean

$(PROJECT): $(OBJECTS)
	$(CC) -ccbin $(CCBIN) -o $@ $^ $(LDFLAGS) $(LDLIBS)

reload: unload load

unload:
	-rmmod $(MODULE).ko

load:
	insmod $(MODULE).ko num_user_pages=128

userspace/%.c.o: userspace/%.c
	$(CCBIN) -std=gnu11 $(CFLAGS) -pedantic $(DEFINES) $(INCLUDE) -o $@ $< -c

userspace/%.cu.o: userspace/%.cu
	$(CC) -std=c++11 -ccbin $(CCBIN) -Xcompiler "$(CFLAGS) $(DEFINES)" $(INCLUDE) -o $@ $< -c

%:
	$(MAKE) -C $(KDIR) M=$(PWD) $@