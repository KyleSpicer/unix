.PHONY: check debug clean all valgrind profile run

CFLAGS := -std=c18
CFLAGS += -Wall -Wextra -Wpedantic -Wwrite-strings
CFLAGS += -Waggregate-return -Wvla -Wfloat-equal
CFLAGS += -D_GNU_SOURCE

VAL_FLAGS := --leak-check=full --show-leak-kinds=all --track-origins=yes
VAL_FLAGS += --trace-children=yes

PROGRAM_NAME := program
CC := gcc

SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin
TST_DIR := test
BIN := $(BIN_DIR)/$(PROGRAM_NAME)
CHECK := $(BIN_DIR)/$(PROGRAM_NAME)_check

SRCS := $(wildcard $(SRC_DIR)/*.c)
OBJS := $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRCS))

TSTS := $(wildcard $(TST_DIR)/*.c)
TST_OBJS := $(filter-out $(OBJ_DIR)/$(PROGRAM_NAME).o, $(OBJS))
TST_OBJS += $(patsubst $(TST_DIR)/%.c, $(OBJ_DIR)/%.o, $(TSTS))
TST_LIBS := -lcheck -lm -pthread -lrt -lsubunit

all: $(BIN)

debug: CFLAGS += -g3 -D DDEBUG
debug: $(BIN)

check: $(CHECK)

clean: 
	@rm -rf $(OBJ_DIR) $(BIN_DIR) $(CHECK) gmon.out

profile: CFLAGS += -pg
profile: $(BIN)
	./$(BIN)

valgrind: CFLAGS += -D DDEBUG -g3
valgrind: $(BIN) 
	valgrind $(VAL_FLAGS) ./$(BIN)

run: $(BIN)
	./$(BIN)

$(OBJ_DIR):
	@mkdir -p $@

$(BIN_DIR):
	@mkdir -p $@

$(OBJS): | $(OBJ_DIR)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@ -lm

$(OBJ_DIR)/%.o: $(TST_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@ -lm

$(BIN): $(BIN_DIR) $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@ -lm

$(CHECK): $(TST_OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(TST_LIBS)
	./$(CHECK)
