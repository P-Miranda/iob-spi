CORE := iob_spi

DISABLE_LINT:=1

all: test

LIB_DIR ?= ../IOB-SOC/submodules/LIB
PROJECT_ROOT=.

include $(LIB_DIR)/setup.mk

test: clean 
	nix-shell --run "make build-setup && make -C ../iob_spi_* sim-run"
