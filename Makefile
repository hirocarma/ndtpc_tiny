SHELL = /bin/sh

prefix= /usr/local

ndtpc_bindir= /usr/local/bin
ndtpc_libdir= /usr/local/lib/ndtpc

INSTALL= /usr/bin/install -c
INSTALL_PROGRAM= ${INSTALL}
INSTALL_DATA= ${INSTALL} -m 644

mkdir= /usr/bin/mkdir
chmod= /usr/bin/chmod
rm= /usr/bin/rm

PROG= ndtpc

all:
	@echo everything has been done by configure.
	@echo you only need to do "make install".

install:: installbin installdata

installbin::
	[ -d $(ndtpc_bindir) ] || \
		($(mkdir) -p $(ndtpc_bindir) && $(chmod) 755 $(ndtpc_bindir))
	for f in $(PROG); do \
		$(INSTALL) -m 555 $${f} $(ndtpc_bindir)/$${f} ; \
	done

installdata::
	[ -d $(ndtpc_libdir) ] || $(mkdir) -p $(ndtpc_libdir)
	for f in ndtp.pl ; do \
		$(INSTALL) -m 555 $${f} $(ndtpc_libdir)/$${f} ; \
	done
	$(chmod) 755 $(ndtpc_libdir)

clean::
	$(rm) -f $(PROG)

distclean:: clean
	$(rm) -f Makefile config.log config.status config.cache

