.PHONY: run all clean

# Program Name
EXECUTABLE := hexadecimal_val

CC := gcc
CFLAGS := -W -g -z noexecstack

all: $(EXECUTABLE)

run: clean $(EXECUTABLE)
	./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) $(EXECUTABLE).o
	@clear

$(EXECUTABLE): $(EXECUTABLE).s
	$(CC) $(CFLAGS) $< -o $@