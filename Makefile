PREFIX ?= /usr
LIBDIR ?= $(PREFIX)/lib/rofi-passx
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share

.PHONY: install uninstall

install:
	install -d $(DESTDIR)$(LIBDIR)
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(DATADIR)/applications
	
	# Install main script and setup
	install -m 755 rofi-passx $(DESTDIR)$(LIBDIR)/rofi-passx
	install -m 755 rofi-passx-setup $(DESTDIR)$(LIBDIR)/rofi-passx-setup
	
	# Install utility and menu scripts
	install -m 644 util_*.sh menu_*.sh $(DESTDIR)$(LIBDIR)/
	
	# Symlink binaries to BINDIR
	ln -sf $(LIBDIR)/rofi-passx $(DESTDIR)$(BINDIR)/rofi-passx
	ln -sf $(LIBDIR)/rofi-passx-setup $(DESTDIR)$(BINDIR)/rofi-passx-setup
	
	# Install desktop file
	install -m 644 rofi-passx.desktop $(DESTDIR)$(DATADIR)/applications/rofi-passx.desktop

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/rofi-passx
	rm -f $(DESTDIR)$(BINDIR)/rofi-passx-setup
	rm -rf $(DESTDIR)$(LIBDIR)
	rm -f $(DESTDIR)$(DATADIR)/applications/rofi-passx.desktop
