# -----------------------------------------------------------------------------------
# Module Name  : -
# Date Created : 20:30:06 IST, 06 October, 2020 [ Tuesday ]
#
# Author       : pxvi
# Description  : Generic makefile that I use
# -----------------------------------------------------------------------------------
#
# MIT License
#
# Copyright (c) 2020 k-sva
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the Software), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ----------------------------------------------------------------------------------- */

# Switch Declarations
# ----------------------

TESTNAME?=default_run

TB_FILENAME?=./../testbench/integration_top.sv
IP_FILENAME?=./../design/res/mpa_mips.v

COMPILE_FILELIST?=./compile_filelist/compile_filelist.list
REGRESS_LIST?=./mpa_mips_programs.rlist

TOP_NAME?=integration_top
DUMP?=0
LINT?=0
WALL?=0
DESIGN_ONLY?=0
TDEBUG?=0

DOLLAR=$
SEED?=0
RANDOM_REGRESS_SEED?=0
COVER_ARG_VAL?=0
CORES?=1
MC?=0

# Define Switch Decl
# ----------------------

ifdef IMFILE
IMFILE_ARG="+IM_FILE=$(IMFILE)"
TESTNAME=`basename $(IMFILE)`
else
IMFILE_ARG=
endif

ifdef MRFILE
MRFILE_ARG=+MR_FILE=$(MRFILE)
else
MRFILE_ARG=
endif

ifdef DMFILE
DMFILE_ARG=+DM_FILE=$(DMFILE)
else
DMFILE_ARG=
endif

ifdef DO_FILE
DO_CMD= -do $(DO_FILE)
else
DO_CMD= -do "run -all; quit -f"
endif

# Argument Declarations
# ----------------------

ifeq ($(SB),1)
SB_ARG=+SBENABLE
else
SB_ARG=
endif

ifeq ($(TDEBUG),1)
TDEBUG_ARG=+TDEBUG
else
TDEBUG_ARG=
endif

ifeq ($(DUMP),1)
DUMP_ARG=+define+GEN_DUMP
else
endif

ifeq ($(DESIGN_ONLY),1)
FILENAME?=$IP_MIPS_MPA_32/res/mpa_mips.v
else
FILENAME?=./../testbench/integration_top.sv
endif

ifeq ($(WALL),1)
WALL_ARG=-Wall
else
WALL__ARG=
endif

ifeq ($(SEED),0)
RAND_SEED=$(shell date "+%N")
SV_SEED=-sv_seed $(RAND_SEED)
else
RAND_SEED=$(SEED)
SV_SEED=-sv_seed $(SEED)
endif

ifneq ($(RANDOM_REGRESS_SEED),0)
RANDOM_REGRESS_SEED=1
else
RANDOM_REGRESS_SEED=0
endif

# Labels Declarations
# ----------------------

ifeq ($(LINT),1)
all : clean lint lib comp opt sim
else
all : clean lib comp opt sim
endif

comp_only : clean lib comp

ifeq ($(MC),1)
regress : clean lib comp opt regress_mc_sim regress_logs
else
regress : clean lib comp opt regress_sim regress_logs regress_result
endif

# Compilie Time Arguments
# --------------------------------------------
COMP_ARGS=$(DUMP_ARG)

# To Clean Redundant Files and Other Things
# --------------------------------------------
clean:
	@echo "Running Clean Command...";
	@rm -rf *.log *.vcd *.wlf;
	@rm -rf work questa.tops transcript;
	@rm -rf ./debug;
	@rm -rf ./regress_logs;
	@rm -rf ./obj_dir;

# Compilation
# --------------------------------------------
comp:
	@echo "Compiling the files...";
	@vlog \
	-64 \
	-work ./work \
	+acc \
	$(COMP_ARGS) \
	-l compile.log \
	-sv \
	-vopt \
	-writetoplevels questa.tops \
	$(FILENAME) \
	-f $(COMPILE_FILELIST) \
	;
	

# Simulation
# --------------------------------------------
sim:
	@echo "Starting Simulation...";
	@vsim \
	top_opt \
	-wlf vsim.wlf \
	$(DO_CMD) \
	-l $(TESTNAME).log \
	-64 \
	$(SV_SEED) \
	-c \
	$(IMFILE_ARG) \
	$(MRFILE_ARG) \
	$(DMFILE_ARG) \
	$(TDEBUG_ARG) \
	$(SB_ARG) \
	+define+UVM_NO_DPI \
	+UVM_TESTNAME=$(TESTNAME);

# Regress Simulation
# --------------------------------------------
regress_sim:
	@echo "Regression Command...";
	@i=`cat $(REGRESS_LIST) | wc -l`; for j in `seq 1 $(DOLLAR)i`; do \
	pfname=`head -$(DOLLAR)j mpa_mips_programs.rlist | tail -1`; \
	echo "Inside regression command. Running program file $(DOLLAR)pfname"; \
	make sim SB=1 IMFILE=`head -$(DOLLAR)j mpa_mips_programs.rlist | tail -1`; \
	done;

# Multi Core Regress Simulations
# --------------------------------------------
regress_mc_sim:
	@echo "Firing the Regression Command...";
	@./regress_script.sh $(REGRESS_LIST) $(RAND_SEED) $(RANDOM_REGRESS_SEED) $(COVER_ARG_VAL) $(CORES);

# Library Generation
# --------------------------------------------
lib:
	@echo "Making Work Directory...";
	@vlib work;

# For the Optimization
# --------------------------------------------
opt:
	@echo "Running Optimization...";
	@vopt \
	+acc \
	$(TOP_NAME) \
	-o top_opt;

# Generate WLF from VCD
# --------------------------------------------
wave:
	@echo "Converting dump.vcd file to dump.wlf...";
	@echo "Removing all the redundant dumps...";
	@echo "Complete!";
	@vcd2wlf dump.vcd dump.wlf;
	@rm -rf dump.vcd;

# Move the Geberated Debug Logs
# --------------------------------------------
logs:
	@echo "Creating a new ./debug directory...";
	@mkdir ./debug;
	@mv *debug.log ./debug/;
	@echo "Moved all the logs successfully.";

# Move the Geberated Debug Logs
# --------------------------------------------
regress_logs:
	@echo "Organising regression logs...";
	@mkdir regress_logs;
	@mv *.log ./regress_logs/;

# Regress Result
# --------------------------------------------
regress_result:
	@echo "--------------------------------------------------------------------------";
	@echo "Regression Results ";
	@echo "--------------------------------------------------------------------------";
	@tprograms=`cat $(REGRESS_LIST) | wc -l`; tpass=`cat ./regress_logs/*.log | grep "\[ RESULT \] Clean_Run" | wc -l`; tfail=`cat ./regress_logs/*.log | grep "\[ RESULT \] Error_Run" | wc -l`; twarn=`cat ./regress_logs/*.log | grep "\[ RESULT \] Warning" | wc -l`; \
	echo "Total Programs : $(DOLLAR)tprograms"; \
	echo "--------------------------------------------------------------------------"; \
	echo "Passing        : $(DOLLAR)tpass"; \
	echo "Failing        : $(DOLLAR)tfail"; \
	echo "Warning        : $(DOLLAR)twarn"; \
	echo "--------------------------------------------------------------------------";

# For the Qverilog Command
# --------------------------------------------
qv:
	qverilog \
	$(FILENAME);

qvc: clean qv

# Running a Lint using Verilator
# --------------------------------------------
lint:
	@echo "Linting the design..."
	@verilator \
	-f $(COMPILE_FILELIST) \
	$(IP_FILENAME) \
	$(WALL_ARG) \
	--lint-only;
	@echo "Linting Complete!"

# MIPS Misc Files ( IM, DM, MR load files )
# --------------------------------------------
gen_mpa_files:
	@echo "Removing old misc MPA MIPS files..."
	@rm -rf mpa_mips_load_dm_data.bin mpa_mips_load_im_program.bin mpa_mips_load_mr.bin;
	@touch mpa_mips_load_dm_data.bin mpa_mips_load_im_program.bin mpa_mips_load_mr.bin;
	@echo "Created new misc MPA MIPS files..."
