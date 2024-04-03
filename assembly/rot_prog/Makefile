.PHONY: check debug clean all run valgrind

CFLAGS := -W -g -z noexecstack

VAL_FLAGS := -s --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes

SRC_DIR := src
OBJ_DIR := obj
TST_DIR := test

SRCS := $(wildcard $(SRC_DIR)/*.s)
OBJS := $(patsubst $(SRC_DIR)/%.s, $(OBJ_DIR)/%.o, $(SRCS))

BIN := rot
CHECK := $(BIN)_check
CC:= gcc-9

TSTS := $(wildcard $(TST_DIR)/*.s)
TST_OBJS := $(filter-out $(OBJ_DIR)/$(BIN).o, $(OBJS))
TST_OBJS += $(patsubst $(TST_DIR)/%.s, $(OBJ_DIR)/%.o, $(TSTS))
TST_LIBS := -lcheck -lm -pthread -lrt -lsubunit

# TEST_SCRIPT := check_perrin.sh

all: clean $(BIN)

run: clean $(BIN)
	@./$(BIN) 
	
debug: CFLAGS += -g3 -D DDEBUG
debug: $(BIN)
	gdb -ex r -ex bt -q --args ./$(BIN) 10 file.txt

#check: clean $(CHECK)
check: 
	cd $(TST_DIR) && ./$(TEST_SCRIPT)

clean:
	@rm -rf $(OBJ_DIR) $(BIN) $(CHECK) gmon.out
	clear

profile: CFLAGS += -g3 -pg
profile: clean $(BIN)

valgrind: CFLAGS += -g3
valgrind: clean $(BIN)
	@valgrind $(VAL_FLAGS) ./$(BIN) 105

$(OBJ_DIR):
	@mkdir -p $@

$(OBJS): | $(OBJ_DIR)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(TST_DIR)/%.s
	@$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(OBJS)
	@$(CC) $(CFLAGS) $^ -o $@

$(CHECK): $(TST_OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(TST_LIBS)
	./$(CHECK) 2> /dev/null
