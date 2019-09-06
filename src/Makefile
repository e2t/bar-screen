TARGET ?= bar-screen
OBJS    = main.o barscreen.o

CPPFLAGS  = $(shell wx-config-static --cxxflags)
LDLIBS    = $(shell wx-config-static --libs)

include ../dry/common.mk

$(TARGET): $(OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)
