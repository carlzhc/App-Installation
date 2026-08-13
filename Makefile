#!/usr/bin/make -f
SHELL := /bin/bash

usage:
	@echo "usage: make <target>"
	@echo "       make <target>-install [DESTDIR=~/app] [PREFIX=/<name>]"
	@echo
	@echo "target:"
	@printf "  %-24s%16s    %s\n" $(foreach app, $(filter-out %-install,$(apps)), $(app) "$(value $(app)_version)" "$(value $(app)_desc)") | LC_ALL=C sort --version-sort

# Install destination prefix
DESTDIR ?= ~/app

# Apps that can be downloaded/installed in this Makefile
apps =

# Operating system
uname_os := $(shell uname -o)

# MSYS environment variable
MSYSTEM ?=

ifeq ($(uname_os), GNU/Linux)
os := linux
ext := .tar.gz
exe :=
else ifeq ($(uname_os), Msys)
os := windows
ext := .zip
exe := .exe
else ifeq ($(uname_os), Android)
os := linux
ext := .tar.gz
else
os := $(uname_os)
ext := .tar.gz
endif

unzip := unzip -DD -n
untar := bsdtar -xmf

arch := $(shell uname -m)
ifeq ($(arch), x86_64)
arch := amd64
endif

# --- Start here -----------------
all: $(apps)

clean:
	-rm -f .*.done

distclean: clean
	-git clean -Xf

.PHONY: all clean distclean pre_install $(apps)
.DELETE_ON_ERROR:

# Prepare before installation
pre_install: .pre_install.done

.pre_install.done:
	mkdir -p $(DESTDIR)
	mkdir -p ~/bin
	@touch $@

# Check required rpms installation before installation.
/usr/bin/lsb_release:
	sudo dnf -y install redhat-lsb-core


# JDK openlogic openjdk: https://www.openlogic.com/openjdk-downloads
apps += openlogic_jdk8
openlogic_jdk8_version := 8u482-b08
openlogic_jdk8_package := openlogic-openjdk-$(openlogic_jdk8_version)-$(os)-x64$(ext)
openlogic_jdk8: $(openlogic_jdk8_package)
$(openlogic_jdk8_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk8_version)/$@

apps += openlogic_jdk8-install
openlogic_jdk8-install: PREFIX ?= /openlogic_jdk8
openlogic_jdk8-install: $(openlogic_jdk8_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac


apps += openlogic_jdk11
openlogic_jdk11_version := 11.0.30+7
openlogic_jdk11_package := openlogic-openjdk-$(openlogic_jdk11_version)-$(os)-x64$(ext)
openlogic_jdk11: $(openlogic_jdk11_package)
$(openlogic_jdk11_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk11_version)/$@

apps += openlogic_jdk11-install
openlogic_jdk11-install: PREFIX ?= /openlogic_jdk11
openlogic_jdk11-install: $(openlogic_jdk11_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac

apps += openlogic_jdk17
openlogic_jdk17_version := 17.0.18+8
openlogic_jdk17_package := openlogic-openjdk-$(openlogic_jdk17_version)-$(os)-x64$(ext)
openlogic_jdk17: $(openlogic_jdk17_package)
$(openlogic_jdk17_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk17_version)/$@

apps += openlogic_jdk17-install
openlogic_jdk17-install: PREFIX ?= /openlogic_jdk17
openlogic_jdk17-install: $(openlogic_jdk17_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac

apps += openlogic_jdk21
openlogic_jdk21_version := 21.0.10+7
openlogic_jdk21_package := openlogic-openjdk-$(openlogic_jdk21_version)-$(os)-x64$(ext)
openlogic_jdk21: $(openlogic_jdk21_package)
$(openlogic_jdk21_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk21_version)/$@

apps += openlogic_jdk21-install
openlogic_jdk21-install: PREFIX ?= /openlogic_jdk21
openlogic_jdk21-install: $(openlogic_jdk21_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac


# Clojure
apps += clojure
clojure_desc := Clojure is a robust, and fast prograamming language.
clojure_version := latest
clojure_current_version := $(shell clojure --version 2>/dev/null | awk '{print $$NF}')
clojure:
	@echo Please run $(MAKE) clojure-install to install Clojure

apps += clojure-install
clojure-install_desc = Install the latest version of clojure.
clojure-install: PREFIX ?= /clojure
clojure-install:
	@set +x; \
	ver=`curl -sSf https://api.github.com/repos/clojure/brew-install/releases/latest | jq -r '.tag_name'`; \
	if [[ $${ver} != "$(clojure_current_version)" ]]; then \
	    echo "-- New release found: $${ver}"; \
	else echo "-- Already installed the Latest version: $${ver}"; exit 1; fi; \
	curl -sSkf -L -O https://github.com/clojure/brew-install/releases/download/$${ver}/linux-install.sh; \
	chmod +x linux-install.sh; \
	dest=$(DESTDIR)$(PREFIX); \
	./linux-install.sh --prefix $$dest && rm -f ./linux-install.sh; \
	test -n "$$MSYSTEM" && patch -d $$dest --strip 0 --forward --batch <$@.msys.patch; \
	$$dest/bin/clj --version


# clj-kondo
apps += clj-kondo
clj-kondo_version := 2025.09.22
clj-kondo_package := clj-kondo-$(clj-kondo_version)-$(os)-$(arch)$(ext)
clj-kondo_desc := A static analyzer and linter for Clojure code.

clj-kondo: $(clj-kondo_package)
$(clj-kondo_package):
	wget -c -O $@.swp https://github.com/clj-kondo/clj-kondo/releases/download/v$(clj-kondo_version)/$@
	mv -f $@.swp $@

apps += clj-kondo-install
clj-kondo-install: PREFIX ?= /clj-kondo
clj-kondo-install: $(clj-kondo_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac


# JRuby https://repo1.maven.org/maven2/org/jruby/jruby-dist/
apps += jruby
jruby_desc := The Ruby Programming Language on the JVM
jruby_version := 10.1.0.0
jruby_package := jruby-dist-$(jruby_version)-bin.tar.gz
jruby: $(jruby_package)
$(jruby_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-dist/$(jruby_version)/$@

# JRuby installation
apps += jruby-install
jruby-install: PREFIX ?= /jruby
jruby-install: $(jruby_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX);; esac

# JRuby-Complete
apps += jruby_complete
jruby_complete_desc := The standalone version of JRuby
jruby_complete_version := $(jruby_version)
jruby_complete_package := jruby-complete-$(jruby_complete_version).jar
jruby_complete: $(jruby_complete_package)
$(jruby_complete_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-complete/$(jruby_complete_version)/$@


# JRuby_Complete installation
apps += jruby_complete-install
jruby_complete-install: PREFIX ?= /jruby-complete
jruby_complete-install: $(jruby_complete_package)
	install -m 755 -p -D $< $(DESTDIR)$(PREFIX)/bin/$<


# Maven
apps += maven
maven_version := 3.9.16
maven_package := apache-maven-$(maven_version)-bin$(ext)
maven: $(maven_package)
$(maven_package):
	wget -c https://dlcdn.apache.org/maven/maven-3/$(maven_version)/binaries/$@

apps += maven-install
maven-install: PREFIX ?= /maven
maven-install: $(maven_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1;; esac


# Warbler
apps += warbler
warbler_version := 2.1.0
warbler_package := warbler-$(warbler_version).tar.gz
warbler: $(warbler_package)
$(warbler_package):
	wget -c -O $@ https://github.com/jruby/warbler/archive/refs/tags/v$(warbler_version).tar.gz


apps += warbler-install
warbler-install: PREFIX ?= /warbler
warbler-install: $(warbler_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)$(PREFIX);; *.tar.*) $(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1;; esac


# TinyGo https://github.com/tinygo-org/tinygo/releases
apps += tinygo
tinygo_version := 0.41.1
tinygo_package := tinygo$(tinygo_version).$(os)-$(arch)$(ext)

tinygo: $(tinygo_package)
$(tinygo_package):
	wget -c -O $@ https://github.com/tinygo-org/tinygo/releases/download/v$(tinygo_version)/$@

# TinyGo-install
apps += tinygo-install
tinygo-install: PREFIX ?= /tinygo
tinygo-install: $(tinygo_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1


# Golang https://go.dev/dl/
apps += golang
golang_version := 1.26.5
golang_package := go$(golang_version).$(os)-$(arch)$(ext)

golang: $(golang_package)
$(golang_package):
	wget -c -O $@ https://go.dev/dl/$@

apps += golang-install
golang-install: PREFIX ?= /golang
golang-install: $(golang_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1


# Graalvm https://www.oracle.com/java/technologies/downloads/#graalvmjava23-windows
apps += graalvm
graalvm_desc := High-performance, polyglot runtime environment and JDK
graalvm_version := 25
graalvm_package := graalvm-jdk-$(graalvm_version)_$(os)-x64_bin$(ext)
graalvm: $(graalvm_package)
$(graalvm_package):
	wget -c -O $@ https://download.oracle.com/graalvm/$(graalvm_version)/latest/$@


apps += graalvm-install
graalvm-install: vswhere='/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
graalvm-install: PREFIX ?= /graalvm
graalvm-install: $(graalvm_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1
ifdef MSYSTEM
	if [[ -x "$(vswhere)" ]]; then \
	  instdir="`$(vswhere) -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`"; \
	  if [[ $$instdir ]]; then \
	    (echo -e '2\ni'; echo -E "call \"$$instdir\VC\Auxiliary\Build\vcvars64.bat\""; echo -e '.\nw!\nq') | ex $(DESTDIR)$(PREFIX)/bin/native-image.cmd; \
	  fi; \
	fi
endif


# leiningen
apps += leiningen
leiningen_version := stable
leiningen_desc := For automating Clojure projects without setting your hair on fire
leiningen: lein.tar
lein.tar:
	wget -c https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	chmod +x lein
	bsdtar -cf $@ -s ",^,bin/," lein
	rm -f lein

apps += leiningen-install
leiningen-install: PREFIX ?= /leiningen
leiningen-install: lein.tar
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX)


# Bitwarden Cli
apps += bitwarden
bitwarden_version := latest
bitwarden_desc := The most trusted password manager
bw_package := bw.zip

bitwarden: $(bw_package)
$(bw_package):
	wget -c -O $@ 'https://vault.bitwarden.com/download/?app=cli&platform=$(os)'

apps += bitwarden-install
bitwarden-install: PREFIX ?= /bitwarden
bitwarden-install: $(bw_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ",^,bin/,"


# Babashka https://github.com/babashka/babashka/releases
apps += babashka
babashka_version := 1.12.218

ifeq ($(os), linux)
babashka_package := babashka-$(babashka_version)-$(os)-$(arch)-static$(ext)
else ifeq ($(os), windows)
babashka_package := babashka-$(babashka_version)-$(os)-$(arch)$(ext)
endif

babashka: $(babashka_package)
$(babashka_package):
	wget -c -O $@ https://github.com/babashka/babashka/releases/download/v$(babashka_version)/$(babashka_package)

apps += babashka-install
babashka-install: PREFIX ?= /babashka
babashka-install: $(babashka_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ',^,bin/,'


ifeq ($(os), windows)
# Emacs https://www.gnu.org/software/emacs/download.html
apps += emacs
emacs_version := 30.1
emacs_package := emacs-$(emacs_version).zip

emacs: $(emacs_package)
$(emacs_package):
	wget -c -O $@ https://ftp.gnu.org/gnu/emacs/windows/emacs-$(firstword $(subst ., ,$(emacs_version)))/${emacs_package}

apps += emacs-install
emacs-install: PREFIX ?= /emacs
emacs-install: $(emacs_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX)
endif


## Raku, Perl 6.
apps += rakudo
rakudo_version := 2026.05-01
rakudo_desc := Perl 6
ifneq ($(MSYSTEM),)
rakudo_package := rakudo-moar-$(rakudo_version)-win-x86_64-msvc.zip
else
rakudo_package := rakudo-moar-$(rakudo_version)-linux-x86_64-gcc.tar.gz
endif

# https://rakudo.org/
rakudo: $(rakudo_package)
$(rakudo_package):
	wget -c -O $@ https://rakudo.org/dl/rakudo/$(rakudo_package)

apps += rakudo-install
rakudo-install: PREFIX ?= /rakudo
rakudo-install: $(rakudo_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1


ifeq ($(uname_os), Msys)
# The source file create-short.c is from git-sdk library
# https://github.com/git-for-windows/build-extra
apps += create-shortcut
create-shortcut_desc := Create shortcut from command line
create-shortcut: create-shortcut.tar
create-shortcut.c:
	wget https://raw.githubusercontent.com/git-for-windows/build-extra/main/git-extra/$@
create-shortcut.exe: create-shortcut.c
	/ucrt64/bin/gcc -o $@ $^ -luuid -lole32
create-shortcut.tar: create-shortcut.exe
	$(tar) -cf $@ -s ',^,bin/,' $^

apps += create-shortcut-install
create-shortcut-install: PREFIX ?= /bin
create-shortcut-install: create-shortcut.tar
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX)
endif


apps += github_cli
github_cli_version := 2.87.3
github_cli_desc := GitHub CLI
ifeq ($(uname_os), Msys)
github_cli_package := gh_$(github_cli_version)_windows_$(arch).zip
else
github_cli_package := gh_$(github_cli_version)_linux_$(arch).tar.gz
endif

github_cli: $(github_cli_package)
$(github_cli_package):
	wget -c -O $@ https://github.com/cli/cli/releases/download/v$(github_cli_version)/$(github_cli_package)

apps += github_cli-install
github_cli-install: PREFIX ?= /github_cli
github_cli-install: $(github_cli_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) --strip-components=1


apps += aichat
aichat_version := v0.30.0
aichat_desc := All-in-one LLM CLI tool
ifeq ($(uname_os), Msys)
aichat_package := aichat-$(aichat_version)-x86_64-pc-windows-msvc.zip
else
aichat_package := aichat-$(aichat_version)-x86_64-unknown-linux-musl.tar.gz
endif

aichat: $(aichat_package)
$(aichat_package):
	wget -c -O $@ https://github.com/sigoden/aichat/releases/download/$(aichat_version)/$(aichat_package)

apps += aichat-install
aichat-install: PREFIX ?= /aichat
aichat-install: $(aichat_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ',^,bin/,'


apps += just
just_version := 1.42.4
ifeq ($(uname_os), Msys)
just_package := just-$(just_version)-x86_64-pc-windows-msvc.zip
else
just_package := just-$(just_version)-x86_64-unknown-linux-musl.tar.gz
endif

just: $(just_package)
$(just_package):
	wget -c -O $@ https://github.com/casey/just/releases/download/$(just_version)/$(just_package)

apps += just-install
just-install: PREFIX ?= /just
just-install: $(just_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ',^just.*,bin/~,'


ifdef MSYSTEM
apps += jellyfin-ffmpeg
ffmpeg_version := 7.1.2-1
ffmpeg_package := jellyfin-ffmpeg_$(ffmpeg_version)_portable_win64-clang-gpl.zip

jellyfin-ffmpeg:$(ffmpeg_package)
$(ffmpeg_package):
	wget -c -O $@.swp https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v$(ffmpeg_version)/$@
	mv -f $@.swp $@

apps += jellyfin-ffmpeg-install
jellyfin-ffmpeg-install: PREFIX = ~/jellyfin
jellyfin-ffmpeg-install: $(ffmpeg_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ',^,bin/,' '*.exe'
endif


apps += venice
venice_desc = Venice, a Clojure inspired sandboxed as a safe scripting language.
venice_version = 1.13.6
venice_package = venice-$(venice_version).jar
venice: $(venice_package)
$(venice_package):
	wget -c -O $@ "https://repo1.maven.org/maven2/com/github/jlangch/venice/$(venice_version)/$@"


define venice_launcher =
#!/bin/bash

REPL_HOME=~/app/venice
if [[ $$@ ]]; then
    exec java -jar $$REPL_HOME/libs/$(venice_package) "$$@"
else
    cd $$REPL_HOME && exec ./repl.sh
fi
endef
export venice_launcher

apps += venice-install
venice-install: PREFIX ?= /venice
venice-install: TOPDIR = $(DESTDIR)$(PREFIX)
venice-install: $(venice_package)
	mkdir -p $(TOPDIR)/bin
	rm -f $(TOPDIR)/libs/venice-*.jar
	java -jar $< -setup -colors-dark -dir $(TOPDIR)
	printf "%s\n" "$$venice_launcher" | tee $(TOPDIR)/bin/venice
	chmod +x $(TOPDIR)/bin/venice
ifdef MSYSTEM
	rm -f $(TOPDIR)/repl.*
	unzip -p $< com/github/jlangch/venice/setup/repl.sh | \
	  sed -e 's!{{INSTALL_PATH}}!$(TOPDIR)!' -e '/-cp /s!libs:!libs;!' > $(TOPDIR)/repl.sh
	unzip -p $< com/github/jlangch/venice/setup/repl.unix.env | \
	  sed -e 's/COLOR_MODE=light/COLOR_MODE=dark/' > $(TOPDIR)/repl.env
endif

apps += venice-standalone
venice-standalone_desc = Venice standalone jar.
venice-standalone_version := $(venice_version)
venice-standalone: wd := $(shell mktemp -d)
venice-standalone: venice-standalone-$(venice_version).jar
venice-standalone-$(venice_version).jar: venice-standalone-pom.xml.m4
	cp -t $(wd) $<
	m4 -Dm4_VERSION=$(venice_version) $(wd)/$< | tee $(wd)/pom.xml
	mvn -B -f $(wd) package
	cp -f $(wd)/target/$@ .
	-rm -rf $(wd)

apps += venice-standalone-install
venice-standalone-install: PREFIX ?= /venice
venice-standalone-install: venice-standalone
	install -D venice-standalone-$(venice_version).jar $(DESTDIR)$(PREFIX)/bin/venice-standalone.jar

apps += mg
mg_desc = OpenBSD Mg editor.
mg_version = latest
mg_package = mg-master.zip
mg: $(mg_package)
$(mg_package):
	wget -c -O $@ "https://github.com/troglobit/mg/archive/refs/heads/master.zip"

apps += mg-install
mg-install: t := $(shell mktemp -d)
mg-install: w := $t/$(basename $(mg_package))
mg-install: PREFIX ?= /mg
mg-install: $(mg_package)
	unzip $(mg_package) -d $t
	cd $w && ./autogen.sh
	cd $w && ./configure --without-curses --prefix $(PREFIX) LDFLAGS=-static
	cd $w && $(MAKE) DESTDIR=$(DESTDIR) install clean
	rm -rf $t

ifdef MSYSTEM
apps += clisp
clisp_desc = An ANSI Common Lisp
clisp_version = 2.49
clisp_package = clisp-$(clisp_version)-win32-mingw-big.zip
clisp: $(clisp_package)
$(clisp_package):
	wget -c -O $@ "https://master.dl.sourceforge.net/project/clisp/clisp/$(clisp_version)/$@?viasf=1"

apps += clisp-install
clisp-install: PREFIX ?= /clisp
clisp-install: $(clisp_package)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(untar) $< -C $(DESTDIR)$(PREFIX)
	echo -e '#!/bin/sh\n_t=$$(dirname $$(dirname $$(readlink -f "$$0")))\nexec $$_t/$$(basename "$$0") "$$@"' > $(DESTDIR)$(PREFIX)/bin/clisp
	cp -f $(DESTDIR)$(PREFIX)/bin/clisp $(DESTDIR)$(PREFIX)/bin/clisp-link
	chmod +x -R $(DESTDIR)$(PREFIX)/bin
endif

ifndef MSYSTEM
apps += schemesh
schemesh_version := v0.9.2
schemesh_desc := A Unix shell and Lisp REPL, fused together.
schemesh_package :=  schemesh-$(schemesh_version).tar.gz
schemesh_builddir := $(patsubst %.tar.gz, %, $(schemesh_package))

schemesh: $(schemesh_builddir)/schemesh
$(schemesh_builddir)/schemesh: $(schemesh_package)
	test -e "/usr/include/lz4.h" || { echo "E: package not installed: liblz4-dev"; exit 1; }
	test -e "/usr/include/ncurses.h" || { echo "E: package not installed: libncurses-dev"; exit 1; }
	test -e "/usr/include/uuid/uuid.h" || { echo "E: package not installed: uuid-dev"; exit 1; }
	test -e "/usr/include/zlib.h" || { echo "E: package not installed: zlib1g-dev"; exit 1; }
	test -e "/usr/share/doc/chezscheme-dev/NOTICE" || { echo "E: package not installed:  chezscheme-dev"; exit 1; }
	rm -rf $(schemesh_builddir)
	mkdir -p $(schemesh_builddir)
	$(untar) $< -C $(schemesh_builddir) --strip-components=1
	cd $(schemesh_builddir) && $(MAKE) CC='gcc -fno-lto'

$(schemesh_package):
	wget -c -O $@ "https://github.com/cosmos72/schemesh/archive/refs/tags/$(schemesh_version).tar.gz"

schemesh-install: PREFIX ?= /schemesh
schemesh-install: $(schemesh_builddir)/schemesh
	cd $(schemesh_builddir) && $(MAKE) install DESTDIR=$(DESTDIR) prefix=$(PREFIX)
	$(DESTDIR)$(PREFIX)/bin/schemesh -e 1
	-rm -rf $(schemesh_builddir)
endif


apps += closh
closh_desc = Bash-like shell based on Clojure
closh_version = 0.5.0
closh_package = closh-zero.jar
closh: $(closh_package)
$(closh_package):
	wget -c -O $@ "https://github.com/dundalek/closh/releases/download/v$(closh_version)/$(closh_package)"


apps += closh-install
closh-install: PREFIX = /closh
closh-install: $(closh_package)
	install -D -t $(DESTDIR)$(PREFIX)/bin $<
	echo -e '#!/usr/bin/sh\nexec java -jar $(DESTDIR)$(PREFIX)/bin/$< "$$@"' > $(DESTDIR)$(PREFIX)/bin/closh
	chmod +x $(DESTDIR)$(PREFIX)/bin/closh


apps += gopass
gopass_desc = The slightly more awesome standard unix password manager for teams
gopass_version = 1.16.1
gopass_package = gopass-$(gopass_version)-$(os)-amd64$(ext)
gopass: $(gopass_package)
$(gopass_package):
	wget -c -O $@ "https://github.com/gopasspw/gopass/releases/download/v$(gopass_version)/$(gopass_package)"

gopass-install: PREFIX ?= /gopass
gopass-install: $(gopass_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s  ',^gopass,bin/~,'

apps += git-credential-gopass
git-credential-gopass_desc := Gopass git-credentials helper
git-credential-gopass_version := 1.16.1
git-credential-gopass_package := git-credential-gopass-$(git-credential-gopass_version)-$(os)-amd64$(ext)

git-credential-gopass: $(git-credential-gopass_package)
$(git-credential-gopass_package):
	wget -c -O $@ "https://github.com/gopasspw/git-credential-gopass/releases/download/v$(git-credential-gopass_version)/$(git-credential-gopass_package)"

git-credential-gopass-install: PREFIX ?= /git-credential-gopass
git-credential-gopass-install: $(git-credential-gopass_package)
	mkdir -p $(DESTDIR)$(PREFIX)
	$(untar) $< -C $(DESTDIR)$(PREFIX) -s ',^git.*,bin/~,'

## Add more here.



## Add dependencies to all -install targets
$(filter %-install,$(apps)): | pre_install
