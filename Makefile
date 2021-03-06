# dbgcheck Makefile
#
# This library is meant to be used by including dbgcheck/dbgcheck.h and linking
# with dbgcheck.o.
#
# The primary rules are:
#
# * all   -- Builds everything in the out/ directory.
# * test  -- Builds and runs all tests, printing out the results.
# * clean -- Deletes everything this makefile may have created.
#


#################################################################################
# Variables for targets.

tests = out/dbgcheck_test

cstructs_obj = out/array.o out/map.o out/list.o

includes = -I.

universal_flags = $(includes) -std=c99 -Ddbgcheck_on

ifeq ($(shell uname -s), Darwin)
	cflags = $(universal_flags)
else
	cflags = $(universal_flags) -D _GNU_SOURCE
endif
cc = gcc $(cflags)

# Test-running environment.
testenv = DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib MALLOC_LOG_FILE=/dev/null


#################################################################################
# Primary rules; meant to be used directly.

# Build everything.
all: out/dbgcheck.o $(tests)

# Build and run all tests.
test: $(tests)
	@echo Running tests:
	@echo -
	@for test in $(tests); do $(testenv) $$test || exit 1; done
	@echo -
	@echo All tests passed!

clean:
	rm -rf out/

#################################################################################
# Internal rules; meant to only be used indirectly by the above rules.

out/dbgcheck.o: dbgcheck/dbgcheck.c dbgcheck/dbgcheck.h | out
	$(cc) -o $@ -c $<

out/thready.o: thready/thready.c thready/thready.h | out
	$(cc) -o $@ -c $< -pthread

$(cstructs_obj) : out/%.o : cstructs/%.c cstructs/%.h | out
	$(cc) -o $@ -c $<

out/ctest.o : test/ctest.c test/ctest.h | out
	$(cc) -o $@ -c $<

$(tests) : out/% : test/%.c $(cstructs_obj) out/dbgcheck.o out/thready.o out/ctest.o | out
	$(cc) -o $@ $^ -pthread

out:
	mkdir out

# The PHONY rule tells the makefile to ignore directories with the same name as a rule.
.PHONY: test
