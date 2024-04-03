.PHONY: run all clean

# Program Name
EXECUTABLE := my_strtol

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