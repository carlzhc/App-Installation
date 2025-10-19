#!/usr/bin/make -f

usage:
	@echo "usage: make [target...]"
	@echo "target:"
	@printf "  %-24s%12s    %s\n" $(foreach app, $(apps), $(app) "$(value $(app)_version)" "$(value $(app)_desc)") | LC_ALL=C sort --version-sort

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
untar := tar -xamf

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


# JDK
apps += openlogic_jdk8
openlogic_jdk8_version := 8u422-b05
openlogic_jdk8_package := openlogic-openjdk-$(openlogic_jdk8_version)-$(os)-x64$(ext)
openlogic_jdk8: $(openlogic_jdk8_package)
$(openlogic_jdk8_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk8_version)/$@

apps += openlogic_jdk8-install
openlogic_jdk8-install: $(openlogic_jdk8_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac


apps += openlogic_jdk11
openlogic_jdk11_version := 11.0.24+8
openlogic_jdk11_package := openlogic-openjdk-$(openlogic_jdk11_version)-$(os)-x64$(ext)
openlogic_jdk11: $(openlogic_jdk11_package)
$(openlogic_jdk11_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk11_version)/$@

apps += openlogic_jdk11-install
openlogic_jdk11-install: $(openlogic_jdk11_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

apps += openlogic_jdk17
openlogic_jdk17_version := 17.0.12+7
openlogic_jdk17_package := openlogic-openjdk-$(openlogic_jdk17_version)-$(os)-x64$(ext)
openlogic_jdk17: $(openlogic_jdk17_package)
$(openlogic_jdk17_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk17_version)/$@

apps += openlogic_jdk17-install
openlogic_jdk17-install: $(openlogic_jdk17_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

apps += openlogic_jdk21
openlogic_jdk21_version := 21.0.4+7
openlogic_jdk21_package := openlogic-openjdk-$(openlogic_jdk21_version)-$(os)-x64$(ext)
openlogic_jdk21: $(openlogic_jdk21_package)
$(openlogic_jdk21_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk21_version)/$@

apps += openlogic_jdk21-install
openlogic_jdk21-install: $(openlogic_jdk21_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac


# TruffleRuby https://github.com/oracle/truffleruby/releases
apps += truffleruby
truffleruby_version := 24.0.2
truffleruby_package := truffleruby-$(truffleruby_version)-$(os)-$(arch)$(ext)
truffleruby: $(truffleruby_package)
$(truffleruby_package):
	wget -c -O $@ https://github.com/oracle/truffleruby/releases/download/graal-$(truffleruby_version)/$(truffleruby_package)

apps += truffleruby-install
truffleruby_dir := $(DESTDIR)$(patsubst %.tar.gz,%,$(truffleruby_package))/
truffleruby_bin := $(truffleruby_dir)bin/truffleruby
truffleruby_ref := https://www.graalvm.org/latest/reference-manual/ruby/RubyManagers/#using-truffleruby-without-a-ruby-manager
$(truffleruby_bin): $(truffleruby_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

truffleruby_deps := $(truffleruby_dir)src/main/c/openssl/openssl.so $(truffleruby_dir)src/main/c/psych/psych.so
$(truffleruby_deps):
	distrib=$$(lsb_release -i | cut -f2); \
	case "$$distrib" in \
	    RedHatEnterpriseServer) repo='codeready-rebuilder*';; \
	    CentOSStream) repo=powertools;; \
	    *) repo='*';; \
	esac; \
	set -ex; for p in openssl-devel libyaml-devel zlib-devel gcc; do \
	    rpm -q $$p &>/dev/null || sudo dnf -y install --enablerepo="$$repo" $$p; done;
	cd $(truffleruby_dir) && lib/truffle/post_install_hook.sh
	@test -z "$${GEM_HOME}" || echo -e "** Please unset environment variable \e[31mGEM_HOME\e[0m, see $(truffleruby_ref)"
	@test -z "$${GEM_PATH}" || echo -e "** Please unset environment variable \e[31mGEM_PATH\e[0m, see $(truffleruby_ref)"

truffleruby-install: pre_install $(truffleruby_bin) $(truffleruby_deps)


# fpm for unpacking rpm files
apps += fpm-install
fpm := $(truffleruby_dir)/bin/fpm
fpm-install: $(fpm)
$(fpm): $(truffleruby_bin)
	$(truffleruby_bin) -S gem install fpm


# Clojure
apps += clojure-install
clojure-install_version = 1.12.2.1571
clojure-install_desc = Install the latest version of clojure.
clojure-install:
	ver=`curl -sSf https://api.github.com/repos/clojure/brew-install/releases/latest | jq -r '.tag_name'`; \
	if [[ $${ver} != $(clojure-install_version) ]]; then \
	    echo "-- New release found: $${ver}"; fi
	curl -L -O https://github.com/clojure/brew-install/releases/download/$(clojure-install_version)/linux-install.sh
	chmod +x linux-install.sh
	./linux-install.sh --prefix $(DESTDIR)/clojure


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
clj-kondo-install: DESTDIR = ~/bin
clj-kondo-install: $(clj-kondo_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac


# JRuby https://repo1.maven.org/maven2/org/jruby/jruby-dist/
apps += jruby
jruby_version := 9.4.8.0
jruby_package := jruby-dist-$(jruby_version)-bin.tar.gz
jruby: $(jruby_package)
$(jruby_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-dist/$(jruby_version)/$@

# JRuby installation
apps += jruby-install
jruby-install: $(jruby_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

# JRuby-Complete
apps += jruby_complete
jruby_complete_version := $(jruby_version)
jruby_complete_package := jruby-complete-$(jruby_complete_version).jar
jruby_complete: $(jruby_complete_package)
$(jruby_complete_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-complete/$(jruby_complete_version)/$@


# JRuby_Complete installation
apps += jruby_complete-install
jruby_complete-install: ~/bin/$(jruby_complete_package)
~/bin/$(jruby_complete_package): $(jruby_complete_package)
	cp -f $< $@


# Maven
apps += maven
maven_version := 3.9.11
maven_package := apache-maven-$(maven_version)-bin$(ext)
maven: $(maven_package)
$(maven_package):
	wget -c https://dlcdn.apache.org/maven/maven-3/$(maven_version)/binaries/$@

apps += maven-install
maven-install: $(maven_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

# Maven-package
apps += maven-rpm
maven_arch := noarch
maven-rpm_file := apache-maven-$(maven_version).$(maven_arch).rpm
maven-rpm_desc := Install maven from the RPM package
maven-rpm: $(maven-rpm_file)
	$(fpm) -s tar -t rpm -n apache-maven -a $(maven_arch) --prefix $(DESTDIR) $<


# Warbler
apps += warbler
warbler_version := 2.0.5
warbler_package := warbler-$(warbler_version).tar.gz
warbler: $(warbler_package)
$(warbler_package):
	wget -c -O $@ https://github.com/jruby/warbler/archive/refs/tags/v$(warbler_version).tar.gz


# TinyGo https://github.com/tinygo-org/tinygo/releases
apps += tinygo
tinygo_version := 0.39.0
tinygo_package := tinygo$(tinygo_version).$(os)-$(arch)$(ext)

tinygo: $(tinygo_package)
$(tinygo_package):
	wget -c -O $@ https://github.com/tinygo-org/tinygo/releases/download/v$(tinygo_version)/$@

# TinyGo-install
apps += tinygo-install
tinygo-install: $(DESTDIR)/tinygo/lib/musl/COPYRIGHT
$(DESTDIR)/tinygo/lib/musl/COPYRIGHT: $(tinygo_package)
	mkdir -p $(DESTDIR)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR) --skip-old-files;; esac


# Golang https://go.dev/dl/
apps += golang
golang_version := 1.24.4
golang_package := go$(golang_version).$(os)-$(arch)$(ext)

golang: $(golang_package)
$(golang_package):
	wget -c -O $@ https://go.dev/dl/$@

apps += golang-install
golang-install: $(DESTDIR)/golang/go$(golang_version)/root/VERSION
$(DESTDIR)/golang/go$(golang_version)/root/VERSION: $(golang_package)
	mkdir -p $(DESTDIR)/golang/go$(golang_version)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR)/golang;; *.tar.*) $(untar) $< -C $(DESTDIR)/golang;; esac
	mv $(DESTDIR)/golang/go $(DESTDIR)/golang/go$(golang_version)/root
	ln -snf golang/go$(golang_version)/root $(DESTDIR)/goroot
	mkdir -p $(DESTDIR)/golang/go$(golang_version)/path
	ln -snf golang/go$(golang_version)/path $(DESTDIR)/gopath


# Graalvm https://www.oracle.com/java/technologies/downloads/#graalvmjava23-windows
apps += graalvm
graalvm_desc := High-performance, polyglot runtime environment and JDK
graalvm_version := 25
graalvm_package := graalvm-jdk-$(graalvm_version)_$(os)-x64_bin$(ext)
graalvm: $(graalvm_package)
$(graalvm_package):
	wget -c -O $@ https://download.oracle.com/graalvm/$(graalvm_version)/latest/$@


apps += graalvm-install
ifdef MSYSTEM
graalvm-install: vswhere='/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
graalvm-install: $(graalvm_package)
	unzip $< -d ~/app/
	if [[ -x $(vswhere) ]]; then \
	  instdir="`$(vswhere) -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`"; \
	  if [[ $$instdir ]]; then \
	    (echo -e '2\ni'; echo -E "call \"$$instdir\VC\Auxiliary\Build\vcvars64.bat\""; echo -e '.\nw!\nq') | ex  ~/app/graalvm-jdk-$(graalvm_version)*/bin/native-image.cmd; \
	  fi; \
	fi
else
graalvm-install: $(graalvm_package)
	mkdir -p $(DESTDIR)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR) --skip-old-files;; esac
endif

# Graalvm-package
apps += graalvm-rpm
graalvm_arch := x86_64
graalvm_rpm := apache-graalvm-$(graalvm_version).$(graalvm_arch).rpm
graalvm-rpm: $(graalvm_rpm)
$(graalvm_rpm): $(graalvm_package) $(fpm)
	$(fpm) -s tar -t rpm -n graalvm-jdk -a $(graalvm_arch) --prefix $(DESTDIR) $<


# leininage
apps += leiningen
leiningen: lein.zip
lein.zip:
	wget -c https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	chmod +x lein
	zip --move --test $@ lein


# Bitwarden Cli
apps += bitwarden
bitwarden: bw
bw: bw$(ext)
	case "$<" in *.zip) $(unzip) $<;; *.tar.*) $(untar) $<;; esac

bw$(ext):
	wget -c -O $@ 'https://vault.bitwarden.com/download/?app=cli&platform=$(ow)'


# Babashka https://github.com/babashka/babashka/releases
apps += babashka
babashka_version := 1.12.208

ifeq ($(os), linux)
babashka_package := babashka-$(babashka_version)-$(os)-$(arch)-static$(ext)
else ifeq ($(os), windows)
babashka_package := babashka-$(babashka_version)-$(os)-$(arch)$(ext)
endif

babashka: $(babashka_package)
$(babashka_package):
	wget -c -O $@ https://github.com/babashka/babashka/releases/download/v$(babashka_version)/$(babashka_package)

apps += babashka-install
ifeq ($(wildcard ~/bin/.),)
babashka_bindir := $(DESTDIR)babashka-$(babashka_version)/bin
else
babashka_bindir := ~/bin
endif
babashka-install: $(babashka_package)
	mkdir -p $(babashka_bindir)
	case "$<" in *.zip) $(unzip) $< -d $(babashka_bindir);; *.tar.*) $(untar) $< -C $(babashka_bindir);; esac

# Emacs https://www.gnu.org/software/emacs/download.html
apps += emacs
emacs_version := 30.1
emacs_package := emacs-$(emacs_version).zip

emacs: $(emacs_package)
$(emacs_package):
	wget -c -O $@ https://ftp.gnu.org/gnu/emacs/windows/emacs-$(firstword $(subst ., ,$(emacs_version)))/${emacs_package}

apps += emacs-install
emacs-install: $(emacs_package)
	unzip $< -d $(DESTDIR)/emacs/


# JASSPA MicroEmacs
apps += jasspa2009
jasspa2009_version := latest
jasspa2009_package := jasspa-mesrc-$(jasspa2009_version).zip
jasspa2009: $(jasspa2009_package)
$(jasspa2009_package):
	wget -c -O $@ https://github.com/mittelmark/microemacs/archive/refs/heads/master.zip

apps += jasspa2009-install
ifeq ($(wildcard ~/bin/.),)
jasspa2009_bindir := $(DESTDIR)jasspa-$(babashka_version)/bin
else
jasspa2009_bindir := ~/bin
endif
jasspa2009-install: $(jasspa2009_bindir)/mec2009$(exe)
$(jasspa2009_bindir)/mec2009$(exe): builddir := $(shell mktemp -d --tmpdir jasspa-XXXXXX)
$(jasspa2009_bindir)/mec2009$(exe): $(jasspa2009_package)
	rm -rf $(builddir)/*
	$(unzip) -q $(jasspa2009_package) -d $(builddir)
	cd $(builddir)/microemacs-master/bfs && CC=gcc $(MAKE) && install -v -m 755 -s bfs$(exe) $(@D)
ifdef MSYSTEM
	cd $(builddir)/microemacs-master/src && ./build -t c -m cygwin.gmk -D CONSOLE_LIBS=-lcurses
else
	cd $(builddir)/microemacs-master/src && /bin/make -f linux32gcc.gmk BTYP=c
endif
	cd $(builddir)/microemacs-master/src && find . -type f -name mec$(exe) -exec install -v -m 755 -s {} $@ \;
	cd $(builddir)/microemacs-master && bfs/bfs$(exe) -o $(@D)/mesc2009$(exe) -a $@ jasspa
	-rm -rf $(builddir)


# JASSPA MicroEmacs from github
apps += jasspa
jasspa_version := 20250901
jasspa_package_bundle := Jasspa_MicroEmacs_$(jasspa_version)_packages.zip
jasspa_package_url := https://github.com/bjasspa/jasspa/releases/download/me_$(jasspa_version)/
jasspa_package := me_$(jasspa_version).tar.gz

jasspa: $(jasspa_package_bundle) $(jasspa_package)
$(jasspa_package_bundle):
	wget -c -O $@ $(jasspa_package_url)Jasspa_MicroEmacs_Latest_packages.zip
$(jasspa_package):
	wget -c -O $@ https://github.com/bjasspa/jasspa/archive/refs/tags/$@

apps += jasspa-install
ifeq ($(wildcard ~/bin/.),)
jasspa_bindir := $(DESTDIR)jasspa-$(jasspa_version)/bin
else
jasspa_bindir := ~/bin
endif

jasspa-install: $(jasspa_bindir)/mec$(exe)| pre_install
$(jasspa_bindir)/mec$(exe): builddir := $(shell mktemp -d --tmpdir jasspa-XXXXXXX)
$(jasspa_bindir)/mec$(exe): $(jasspa_package)
	-rm -rf $(builddir)/*
	$(untar) $(jasspa_package) -C $(builddir) --strip-components=2 --wildcards '*/microemacs'
	cd $(builddir) && rm -f bin/*
	cd $(builddir)/src && ./build.sh -t c
	find $(builddir)/bin -type f -perm 755 |xargs cp -v -t $(jasspa_bindir)/
	-rm -rf $(builddir)

apps += jasspa-install-bfs
jasspa-install-bfs_version := v09.12.25.beta2
jasspa-install-bfs_package := jasspa-$(jasspa-install-bfs_version).zip
jasspa-install-bfs_package_url := https://github.com/mittelmark/microemacs/archive/refs/tags/$(jasspa-install-bfs_version).zip

$(jasspa-install-bfs_package):
	wget -c -O $@ $(jasspa-install-bfs_package_url)

jasspa-install-bfs: builddir := $(shell mktemp -d --tmpdir jasspa-XXXXXXX)
jasspa-install-bfs: $(jasspa_package_bundle) $(jasspa_bindir)/mec$(exe) $(jasspa-install-bfs_package)
	-rm -rf $(builddir)/*
	$(unzip) -q $(jasspa-install-bfs_package) -d $(builddir)
	cd $(builddir)/microemacs-*/bfs && $(MAKE) && cp -v bfs$(exe) $(jasspa_bindir)
	$(unzip) -q $(jasspa_package_bundle) -d $(builddir)
	cd $(jasspa_bindir) && ./bfs -a mec$(exe) -o mesc$(exe) $(builddir)/packages/Jasspa_MicroEmacs_$(jasspa_version)_macros.tfs
	-rm -rf $(builddir)
	

apps += phcl-microemacs
phcl-microemacs_pkg := $(patsubst %,phcl-microemacs/%, MicroEmacs-4.21-0.0.src.rpm MicroEmacs-4.21-0.0.x86_64.rpm)
phcl-microemacs: $(phcl-microemacs_pkg)
$(phcl-microemacs_pkg):
	mkdir -p $(@D)
	rsync -Pt rsync://www.phcomp.co.uk/downloads/centos9-x86_64/phcl/$(@F) $(@D)/


## Raku, Perl 6.
apps += rakudo
rakudo_version := 2024.06-01
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
rakudo-install: $(rakudo_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac


# chruby https://github.com/postmodern/chruby/releases
apps += chruby
chruby_version := 0.3.9
chruby_package := chruby-$(chruby_version).tar.gz
chruby: $(chruby_package)
$(chruby_package):
	wget -c -O $@ https://github.com/postmodern/chruby/releases/download/v$(chruby_version)/$(chruby_package)

apps += chruby-install
chruby-install: $(chruby_package)
	$(untar) $(chruby_package)
	$(MAKE) -C chruby-$(chruby_version) install PREFIX=$(DESTDIR)/chruby-$(chruby_version)
	-rm -f ~/.bashrc.d/chruby
	echo "# This file is generated automatically, DO NOT EDIT!" > ~/.bashrc.d/chruby
	echo "source $(DESTDIR)/chruby-$(chruby_version)/share/chruby/chruby.sh" >> ~/.bashrc.d/chruby
	echo "source $(DESTDIR)/chruby-$(chruby_version)/share/chruby/auto.sh" >> ~/.bashrc.d/chruby


# ruby-install, ruby installer https://github.com/postmodern/ruby-install/releases
apps += ruby-installer
ruby-installer_version := 0.9.3
ruby-installer_package := ruby-install-$(ruby-installer_version).tar.gz
ruby-installer: $(ruby-installer_package)
$(ruby-installer_package):
	wget -c -O $@ https://github.com/postmodern/ruby-install/releases/download/v$(ruby-installer_version)/$(ruby-installer_package)

ruby-installer-install: $(ruby-installer_package)
	$(untar) $(ruby-installer_package)
	$(MAKE) -C ruby-install-$(ruby-installer_version) install PREFIX=$(DESTDIR)/ruby-install-$(ruby-installer_version)


ifeq ($(uname_os), Msys)
# The source file create-short.c is from git-sdk library
# https://github.com/git-for-windows/build-extra
apps += create-shortcut
create-shortcut: create-shortcut.exe
create-shortcut.exe: create-shortcut.c
	/ucrt64/bin/gcc -o $@ $^ -luuid -lole32

create-shortcut.c:
	wget https://raw.githubusercontent.com/git-for-windows/build-extra/main/git-extra/$@
endif


apps += github_cli
github_cli_version := 2.76.2
ifeq ($(uname_os), Msys)
github_cli_package := gh_$(github_cli_version)_windows_$(arch).zip
else
github_cli_package := gh_$(github_cli_version)_linux_$(arch).tar.gz
endif

github_cli: $(github_cli_package)
$(github_cli_package):
	wget -c -O $@ https://github.com/cli/cli/releases/download/v$(github_cli_version)/$(github_cli_package)

apps += github_cli-install
github_cli-install: $(github_cli_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac


apps += aichat
aichat_version := v0.30.0
ifeq ($(uname_os), Msys)
aichat_package := aichat-$(aichat_version)-x86_64-pc-windows-msvc.zip
else
aichat_package := aichat-$(aichat_version)-x86_64-unknown-linux-musl.tar.gz
endif

aichat: $(aichat_package)
$(aichat_package):
	wget -c -O $@ https://github.com/sigoden/aichat/releases/download/$(aichat_version)/$(aichat_package)

apps += aichat-install
aichat-install: DESTDIR = ~/bin
aichat-install: $(aichat_package)
	case "$<" in *.zip) $(unzip) $< -d $(DESTDIR);; *.tar.*) $(untar) $< -C $(DESTDIR);; esac

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
just-install: DESTDIR = ~/bin
just-install: $(just_package)
	case "$<" in *.zip) $(unzip) -j -d $(DESTDIR) $< just$(exe);; *.tar.*) $(untar) $< -C $(DESTDIR) just$(exe);; esac

ifdef MSYSTEM
apps += jellyfin-ffmpeg
ffmpeg_version := 7.1.2-1
ffmpeg_package := jellyfin-ffmpeg_$(ffmpeg_version)_portable_win64-clang-gpl.zip

jellyfin-ffmpeg:$(ffmpeg_package)
$(ffmpeg_package):
	wget -c -O $@.swp https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v$(ffmpeg_version)/$@
	mv -f $@.swp $@

apps += jellyfin-ffmpeg-install
jellyfin-ffmpeg-install: DESTDIR = ~/bin
jellyfin-ffmpeg-install: $(ffmpeg_package)
	case "$<" in *.zip) $(unzip) -j -d $(DESTDIR) $< \*$(exe);; *.tar.*) $(untar) $< -C $(DESTDIR) \*$(exe);; esac
endif


apps += venice
venice_desc = Venice, a Clojure inspired sandboxed as a safe scripting language.
venice_version = 1.12.55
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
venice-install: DESTDIR := $(DESTDIR)/venice
venice-install: $(venice_package)
	mkdir -p $(DESTDIR)/bin
	java -jar $< -setup -colors-dark -dir $(DESTDIR)
	printf "%s\n" "$$venice_launcher" | tee $(DESTDIR)/bin/venice
	chmod +x $(DESTDIR)/bin/venice
ifdef MSYSTEM
	rm -f $(DESTDIR)/repl.*
	unzip -p $< com/github/jlangch/venice/setup/repl.sh | sed -e 's!{{INSTALL_PATH}}!$(DESTDIR)!' -e '/-cp /s!libs:!!' > $(DESTDIR)/repl.sh
	unzip -p $< com/github/jlangch/venice/setup/repl.unix.env > $(DESTDIR)/repl.env
endif

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
mg-install: $(mg_package)
	unzip $(mg_package) -d $t
	cd $w && ./autogen.sh
	cd $w && ./configure --without-curses --prefix $(DESTDIR)/mg LDFLAGS=-static
	cd $w && $(MAKE) install clean
	rm -rf $t


## Add more here.



## Add dependencies to all -install targets
$(filter %-install,$(apps)): | pre_install
