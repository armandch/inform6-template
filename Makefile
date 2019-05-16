# Generic Baroque Inform project makefile
# by D. Jacob Wildstrom

# This makefile should be suited to most projects you might ever want
# to handle using Inform. 'make' or 'make rel' will make a final
# version of your program (using abbreviations, disabling debugging,
# and stripping filesize padding off the gamefile). 'make dev' will
# make a debugging-and-development version. 'make clean' does what it
# normally does.

# In order to use the abbreviation-handling powers of this makefile,
# your source code should at some point contain the line
#   Include ">abbreviations.inf";
# You can change that sourcefile's name below.

# The major points at which you'll probably want to configure this
# makefile are the definitions of the variables INFORM, CHECK,
# SOURCE-FILE, AUX-SWITCH, ZVERSION-LIB-PATH, and ABBREVIATIONS-SWITCH

### +----------------------+
### | Environment settings |
### +----------------------+

# This is the path to your inform binary below. One of the following
# will generally be right.

INFORM = /usr/local/bin/inform
# INFORM = /usr/local/bin/inform-6.21

# This is the path to the ztools 'check' utility below, used for
# stripping compiled z-files. One of the following will generally be
# right.

CHECK = /usr/local/bin/check
# CHECK = /usr/local/bin/check

# Put the location of the z3 library (i.e. library version 6/2 or
# earlier), and any other includes necessary in z3 compiles, here.
Z3-INCL-PATH = +include-path=/usr/local/share/inform/old/6.2

# If you need a path setting other than the default, indicate it
# here. You must use ICL notation, so preface any path indication with
# "+".
INFORM-PATHS = 

### +------------------------+
### | Game-specific settings |
### +------------------------+

# This is the name of the source file which you want compiled by Inform.
SOURCE-FILE = main.inf

# Any additional dependencies for the compile should go here.
AUX-SOURCES =

# This is the version of the z-machine to which you're
# compiling. Generally it's going to want to be 5, and occasionally
# 8. You will rarely want a different setting. This makefile is
# special-cased to allow z3 (with the 6/2 libraries and proper setting
# of Z3-INCL-PATH), but z4 needs special-casing even with the 6/2
# libraries, which aren't really made to do z4.
ZVERSION = 5

# Uncomment one of the following lines _only_ if you are not using the
# standard inform libraries (at the time of writing, 6/10). The first
# will disable the -S and -X switches, which depend on using the
# standard libraries and become unhappy if you aren't; the second will
# disable -S, -X, and -D, since libraries without debug hooks (or no
# libraries at all) may also cause errors. Note that
# NONSTANDARD-LIBRARY is automatically defined for Z-machine version 3
# (which uses a previous library version, which is not compatible with
# these switches).

# NONSTANDARD-LIBRARY = yes
# NONSTANDARD-LIBRARY = no-debug

# Depending whether you want to actually create and use abbreviations,
# uncomment one of the two options below.
# Warning: use-abbreviations has a lot of issues, none of them my
# fault. In games with a lot of text, it's slow, and in games with
# very little text, or text which closely matches inform builtin text,
# it throws a segfault -- this is because text hardwired into Inform
# is in consts, but the -e switch isn't smart enough to not try to
# modify them anyways. There is in fact a patch to inform which solves
# this problem, and which you may want to use if you have frequent
# difficulties.

ABBREVIATIONS-SWITCH = use-abbreviations
# ABBREVIATIONS-SWITCH = dont-use-abbreviations

# You can give the abbreviations file any name you want, but there's
# rarely a need to change it from the default.
ABBREV-FILE = abbreviations.inf

# This is the name of the transcript output for compilation using the
# -r switch.
TRANSCRIPT-FILE = transcript.txt

# Uncomment the second if you do not wish to produce a game-text transcript.

ICL-TRANSCRIPT-CMD = +transcript_name=$(TRANSCRIPT-FILE)
# ICL-TRANSCRIPT-CMD = 

# If you have any other parameters you want to pass to Inform, such as
# $huge, put them here.
ICL-PARAMS = 

### +------------------------------------------------------------------+
### | Ideally, you should not have to modify anything below this line. |
### +------------------------------------------------------------------+


# Absurd hack to make Z3 work.
ifeq ($(ZVERSION),3)
ifndef NONSTANDARD-LIBRARY
NONSTANDARD-LIBRARY = yes
endif
ZVERSION-LIB-PATH = $(Z3-INCL-PATH)
else
ZVERSION-LIB-PATH =
endif

# These are respectively the switches and output filename for
# development versions of the z-code.
ifdef NONSTANDARD-LIBRARY
# Special hack -- -S and -X do not do the right thing under
# nonstandard libraries, and under some libraries, -D doesn't work
# either.
ifeq ($(NONSTANDARD-LIBRARY),no-debug)
DEV-PARAMS = -~D~S~Xrv$(ZVERSION)
else
DEV-PARAMS = -D~S~Xrv$(ZVERSION)
endif
else
DEV-PARAMS = -DSXrv$(ZVERSION)
endif
DEV-TARGET = dev-version.z$(ZVERSION)

# These are respectively the switches and output filename for final
# versions of the z-code.

# The distinction between release-version.z* and stripped-release.z*
# is that trailing space (above the internal gamefile size) is
# stripped off of stripped-release with the ztools utility check. In
# practice, it takes up the same amount of space on modern filesystems
# as the padded version, but its ostensible filesize is a more
# accurate indicator of the actual data size.
REL-PARAMS = -~D~S~Xrefsv$(ZVERSION)
REL-TARGET = release-version.z$(ZVERSION)
RELRED-TARGET = stripped-release.z$(ZVERSION)

# These are respectively the switches and output filename for
# abbreviation-determination. Note that the output filename is
# completely arbitrary, since we don't actually care about the z-code
# resulting from an optimization pass.
OPT-PARAMS = -~D~S~Xuv$(ZVERSION)
OPT-TARGET = maketemp.optimize.z$(ZVERSION)

INFORM-WITH-PARAMS = $(INFORM) $(ICL-PARAMS) $(ICL-TRANSCRIPT-CMD) $(INFORM-PATHS) $(ZVERSION-LIB-PATH)

release rel final: $(RELRED-TARGET)

dev develop development test: $(DEV-TARGET)

opt optimize optimization abbreviate abbreviation: $(ABBREV-FILE)

all: rel dev opt

$(RELRED-TARGET): $(REL-TARGET)
	$(CHECK) $(REL-TARGET) $(RELRED-TARGET)

$(REL-TARGET): $(ABBREV-FILE) $(SOURCE-FILE) $(AUX-SOURCES)
	$(INFORM-WITH-PARAMS) $(REL-PARAMS) $(SOURCE-FILE) $(REL-TARGET)

$(DEV-TARGET): $(SOURCE-FILE) $(AUX-SOURCES)
	$(INFORM-WITH-PARAMS) $(DEV-PARAMS) $(SOURCE-FILE) $(DEV-TARGET)

$(ABBREV-FILE): $(SOURCE-FILE) $(AUX-SOURCES)
	$(MAKE) $(ABBREVIATIONS-SWITCH)

use-abbreviations: $(SOURCE-FILE) $(AUX-SOURCES)
	$(INFORM-WITH-PARAMS) $(OPT-PARAMS) $(SOURCE-FILE) $(OPT-TARGET) | grep Abbreviate > $(ABBREV-FILE)
	rm $(OPT-TARGET)

dont-use-abbreviations:
	touch $(ABBREV-FILE)

clean:
	rm -f *~ *.z$(ZVERSION) $(TRANSCRIPT-FILE) $(ABBREV-FILE)
# This is, I know, a hack. It basically insures that $(ABBREV-FILE)
# exists, so that 'make dev' doesn't lose, but also insures that it's
# old enough that it'll want updating for the files which have it as
# dependencies.
	touch -t 197001010000.00 $(ABBREV-FILE)
