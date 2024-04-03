.PHONY: run clean

# Assembler
AS=nasm
ASFLAGS =-f elf64
ASFLAGS += -W
CFLAGS += -01 -masm=intel -fno-asynchronous-unwind-tables

# Linker
LD=ld
LDFLAGS=

# Output file
EXECUTABLE=helloworld

all: $(EXECUTABLE)

run: $(EXECUTABLE)
	./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) helloworld.o

$(EXECUTABLE): helloworld.o
	$(LD) $(LDFLAGS) $< -o $@

helloworld.o: helloworld.asm
	$(AS) $(ASFLAGS) $< -o $@