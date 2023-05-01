CFLAGS := -pedantic -W -Wall -Wconversion -Werror -O2 -flto

all: hexc hexs

hexc: hexc.c
	$(CC) $(CFLAGS) $^ -o $@

hexs: hexs.s
	gcc -no-pie $^ -o $@

clean:
	$(RM) hexc hexs

.PHONY: clean