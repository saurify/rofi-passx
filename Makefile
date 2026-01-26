PREFIX ?= /usr/local
INSTALL_DIR ?= $(PREFIX)/share/rofi-passx
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share

.PHONY: install uninstall

install:
	install -d $(DESTDIR)$(INSTALL_DIR)/bin
	install -d $(DESTDIR)$(INSTALL_DIR)/lib/menu
	install -d $(DESTDIR)$(INSTALL_DIR)/lib/util
	install -d $(DESTDIR)$(INSTALL_DIR)/share
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(DATADIR)/applications
	
	# Install binaries
	install -m 755 bin/rofi-passx $(DESTDIR)$(INSTALL_DIR)/bin/rofi-passx
	install -m 755 bin/rofi-passx-setup $(DESTDIR)$(INSTALL_DIR)/bin/rofi-passx-setup
	
	# Install libraries
	install -m 644 lib/menu/*.sh $(DESTDIR)$(INSTALL_DIR)/lib/menu/
	install -m 644 lib/util/*.sh $(DESTDIR)$(INSTALL_DIR)/lib/util/
	install -m 644 lib/startup.sh $(DESTDIR)$(INSTALL_DIR)/lib/startup.sh
	
	# Install desktop file to repo share dir (for reference)
	install -m 644 share/rofi-passx.desktop $(DESTDIR)$(INSTALL_DIR)/share/rofi-passx.desktop
	
	# Symlink binaries to BINDIR
	ln -sf $(INSTALL_DIR)/bin/rofi-passx $(DESTDIR)$(BINDIR)/rofi-passx
	ln -sf $(INSTALL_DIR)/bin/rofi-passx-setup $(DESTDIR)$(BINDIR)/rofi-passx-setup
	
	# Install desktop file to system applications dir
	ln -sf $(INSTALL_DIR)/share/rofi-passx.desktop $(DESTDIR)$(DATADIR)/applications/rofi-passx.desktop

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/rofi-passx
	rm -f $(DESTDIR)$(BINDIR)/rofi-passx-setup
	rm -rf $(DESTDIR)$(INSTALL_DIR)
	rm -f $(DESTDIR)$(DATADIR)/applications/rofi-passx.desktop
