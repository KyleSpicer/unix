.PHONY: run all clean

# Program Name
EXECUTABLE := strtol

# Assembler
AS := as
ASFLAGS := -nostdlib -W 

CFLAGS := -g

# Linker
LD := ld
LDFLAGS := -pie -z noexecstack -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc

run: clean $(EXECUTABLE)
	./$(EXECUTABLE)

all: $(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) $(EXECUTABLE).o
	@clear

$(EXECUTABLE): $(EXECUTABLE).o
	$(LD) $(LDFLAGS) $< -o $@

$(EXECUTABLE).o: $(EXECUTABLE).s
	$(AS) $(ASFLAGS) $< -o $@
