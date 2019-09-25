
LIN64V19="https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz"
SHA64="d359adbee89823c641cda326938708d7227dc79aa1f162e0d8fe275f182f528a"

LIN32V19="https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
SHA32="7a82bbf34955960d9806417f300e7b2f8d426933c09863797fe83b67063e0139"

RELEASE_DATE="201808211146"

.PHONY: all
all: output/elm_0.19-1-i386.deb output/elm_0.19-1-amd64.deb

orig/amd64.gz:
	@mkdir -p $(shell dirname $@)
	curl -sSL ${LIN64V19} -o $@
	sha256sum --check amd64.sha256sum || rm $@

orig/i386.gz:
	@mkdir -p $(shell dirname $@)
	curl -sSL ${LIN32V19} -o $@
	sha256sum --check i386.sha256sum || rm $@

.PRECIOUS: build/%/usr/bin/elm
build/%/usr/bin/elm: orig/%.gz
	@mkdir -p $(shell dirname $@)
	gunzip < $^ > $@
	chmod +x $@

.PRECIOUS: build/i386/control
build/i386/control: control
	@mkdir -p $(shell dirname $@)
	sed 's/ARCH/i386/' < $^ > $@

.PRECIOUS: build/amd64/control
build/amd64/control: control
	@mkdir -p $(shell dirname $@)
	sed 's/ARCH/amd64/' < $^ > $@

.PRECIOUS: build/%/data.tar
build/%/data.tar: build/%/usr/bin/elm
	@mkdir -p $(shell dirname $@)
	find $(shell dirname $@) -exec touch -t ${RELEASE_DATE} {} \;
	tar --sort=name -cf $@ -C $(shell dirname $@) usr

.PRECIOUS: build/%/control.tar
build/%/control.tar: build/%/control
	@mkdir -p $(shell dirname $@)
	find $(shell dirname $@) -exec touch -t ${RELEASE_DATE} {} \;
	tar --sort=name -cf $@ -C $(shell dirname $@) control

.PRECIOUS: %.tar.gz
%.tar.gz: %.tar
	gzip -n < $^ > $@

.PRECIOUS: build/%/debian-binary
build/%/debian-binary:
	@mkdir -p $(shell dirname $@)
	echo 2.0 > $@

output/elm_0.19-1-%.deb: build/%/debian-binary build/%/control.tar.gz build/%/data.tar.gz
	@mkdir -p $(shell dirname $@)
	ar Dr $@ $^

.PHONY: clean
clean:
	rm -rf build output
