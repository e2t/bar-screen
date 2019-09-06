CXXFLAGS ?= -Wall -Wextra -Wshadow -std=c++17
LDFLAGS   = -static

all: $(TARGET)

run:
	./$(TARGET)

clean:
	$(RM) $(OBJS) $(TARGET)
