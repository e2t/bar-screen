CXXFLAGS = -Wall -Wextra -Wshadow $(shell wx-config --cxxflags)
LDFLAGS = -static $(shell wx-config-static --libs)
LDLIBS =

PROG = bar-screen
OBJS = main.o screen.o

all: $(PROG)

run:
	./$(PROG)

$(PROG): $(OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)

clean:
	$(RM) $(OBJS) $(PROG)
