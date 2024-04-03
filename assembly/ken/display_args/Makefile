.PHONY: run all clean

# Program Name
EXECUTABLE := display_args

CC := gcc
CFLAGS := -W

all: $(EXECUTABLE)

run: clean $(EXECUTABLE)
	./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) $(EXECUTABLE).o
	@clear

$(EXECUTABLE): $(EXECUTABLE).s
	$(CC) $(CFLAGS) $< -o $@