#
# Build targets
#

SHELL := /bin/bash

A_LIBRARIES  := libdsme
SO_LIBRARIES := libdsme libdsme_dbus_if

VERSION := 0.60.28

#
# Install files in this directory
#
INSTALL_PERM  := 644
INSTALL_OWNER := $(shell id -u)
INSTALL_GROUP := $(shell id -g)

INSTALL_A_LIBRARIES                   := libdsme.a
$(INSTALL_A_LIBRARIES) : INSTALL_DIR  := $(DESTDIR)/usr/lib
INSTALL_SO_LIBRARIES                  := libdsme.so libdsme_dbus_if.so
$(INSTALL_SO_LIBRARIES): INSTALL_PERM := 755
$(INSTALL_SO_LIBRARIES): INSTALL_DIR  := $(DESTDIR)/usr/lib
INSTALL_INCLUDES                      := include/dsme/protocol.h     \
                                         include/dsme/messages.h     \
                                         include/dsme/processwd.h    \
                                         include/dsme/state.h        \
                                         include/dsme/state_states.h \
                                         modules/dsme_dbus_if.h
$(INSTALL_INCLUDES)    : INSTALL_DIR  := $(DESTDIR)/usr/include/dsme
#INSTALL_OTHER                         := README
#README: INSTALL_DIR                   := $(DESTDIR)/usr/share/doc/dsme
INSTALL_OTHER                         := dsme.pc dsme_dbus_if.pc
dsme.pc                : INSTALL_DIR  := $(DESTDIR)/usr/lib/pkgconfig
dsme_dbus_if.pc        : INSTALL_DIR  := $(DESTDIR)/usr/lib/pkgconfig

#
# Compiler and tool flags
# C_OPTFLAGS are not used for debug builds (ifdef DEBUG)
# C_DBGFLAGS are not used for normal builds
#
C_GENFLAGS     := -DPRG_VERSION=$(VERSION) -pthread -g \
                  -Wall -Wwrite-strings -Wmissing-prototypes -Werror# -pedantic
C_OPTFLAGS     := -O2 -s
C_DBGFLAGS     := -g -DDEBUG -DDSME_LOG_ENABLE
C_DEFINES      := DSME_POSIX_TIMER DSME_WD_SYNC DSME_BMEIPC
C_INCDIRS      := $(TOPDIR)/include $(TOPDIR)/modules $(TOPDIR) 
MKDEP_INCFLAGS := $$(pkg-config --cflags-only-I glib-2.0)

LD_GENFLAGS := -pthread
LD_LIBPATHS := $(TOPDIR)

# If OSSO_DEBUG is defined, compile in the logging
#ifdef OSSO_LOG
C_OPTFLAGS += -DDSME_LOG_ENABLE
#endif

ifneq (,$(findstring DSME_BMEIPC,$(C_DEFINES)))
export DSME_BMEIPC = yes
endif

ifneq (,$(findstring DSME_MEMORY_THERMAL_MGMT,$(C_DEFINES)))
export DSME_MEMORY_THERMAL_MGMT = yes
endif

#
# Target composition and overrides
#


# libdsme.so and libdsme.a
protocol.o : C_EXTRA_GENFLAGS := -fPIC $$(pkg-config --cflags glib-2.0)
message.o  : C_EXTRA_GENFLAGS := -fPIC
libdsme_C_OBJS                := protocol.o message.o
libdsme_EXTRA_LDFLAGS         := $$(pkg-config --libs glib-2.0)
libdsme.so : LIBRARY_VERSION  := 0.2.0

# libdsme_dbus_if.so
libdsme_dbus_if_C_OBJS                   := modules/dsme_dbus_if.o
modules/dsme_dbus_if.o: C_EXTRA_GENFLAGS := -fPIC
libdsme_dbus_if.so    : LIBRARY_VERSION  := 0.2.0

# TODO: move dsme-exec-helper to modules/
# dsme-exec-helper
dsme-exec-helper_C_OBJS := dsme-exec-helper.o oom.o
dsme-exec-helper.o : C_EXTRA_GENFLAGS := $$(pkg-config --cflags glib-2.0)


#
# This is the topdir for build
#
TOPDIR := $(shell /bin/pwd)

#
# Non-target files/directories to be deleted by distclean
#
DISTCLEAN_DIRS	:=	doc tags

#DISTCLN_SUBDIRS := _distclean_tests

#
# Actual rules
#
include $(TOPDIR)/Rules.make

.PHONY: tags
tags:
	find . -name '*.[hc]'  |xargs ctags

.PHONY: doc
doc:
	doxygen
