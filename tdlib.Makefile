repo := ~/repo/github/tdlib/td
dest := /usr/local
commit = 971684a


all:
	@set -ex
	cd $(repo)
	git checkout $(commit)
	rm -rf build
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=$(dest) ..
	cmake --build .

install:
	@set -ex
	cd $(repo)/build
	ksu -e /bin/cmake --install . --prefix $(dest)


prepare:
	@set -ex
	ksu -e /bin/dnf update -y
	ksu -e /bin/dnf --enablerepo=powertools install -y gperf
	ksu -e /bin/dnf install -y gcc-c++ make git zlib-devel openssl-devel php cmake
	cd $(repo) || git clone https://github.com/tdlib/td.git $(repo)
	cd $(repo)


.ONESHELL:
