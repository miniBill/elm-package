
LIN64V19="https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz"
SHA64="d359adbee89823c641cda326938708d7227dc79aa1f162e0d8fe275f182f528a"

LIN32V19="https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
SHA32="7a82bbf34955960d9806417f300e7b2f8d426933c09863797fe83b67063e0139"

.PHONY: all
all: build/elm_0.19-1-i386.deb build/elm_0.19-1-amd64.deb

build/amd64/original.gz:
	mkdir -p $(shell dirname $@)
	curl -sSL ${LIN64V19} -o $@
	sha256sum --check amd64.sha256sum || rm $@

build/i386/original.gz:
	mkdir -p $(shell dirname $@)
	curl -sSL ${LIN32V19} -o $@
	sha256sum --check i386.sha256sum || rm $@

build/%/data/usr/bin/elm: build/%/original.gz
	mkdir -p $(shell dirname $@)
	gunzip < $^ > $@
	chmod +x $@

build/i386/control: control
	mkdir -p $(shell dirname $@)
	sed 's/ARCH/i386/' < $^ > $@

build/amd64/control: control
	mkdir -p $(shell dirname $@)
	sed 's/ARCH/amd64/' < $^ > $@

build/%/data.tar.gz: build/%/data/usr/bin/elm
	tar czf $@ -C $(shell dirname $@)/data usr

build/%/control.tar.gz: build/%/control
	tar czf $@ -C $(shell dirname $@) control

build/%/debian-binary:
	echo 2.0 > $@

build/elm_0.19-1-%.deb: build/%/debian-binary build/%/control.tar.gz build/%/data.tar.gz
	ar r $@ $^
