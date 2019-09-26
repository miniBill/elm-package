
LIN64V19="https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz"
SHA64="d359adbee89823c641cda326938708d7227dc79aa1f162e0d8fe275f182f528a"

LIN32V19="https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
SHA32="7a82bbf34955960d9806417f300e7b2f8d426933c09863797fe83b67063e0139"

RELEASE_DATE="201808211146"
RELEASE_DATE_HUMAN=$(shell TZ=UTC LANG=C date -d 2018-08-21T11:46:00)

.PHONY: all
all: output/dists/stable/InRelease output/pubkey.gpg
	@echo ">>> sudo apt-key add output/pubkey.gpg <<<"
	@echo ">>> echo "deb http:/.../ stable main" | sudo tee /etc/apt/sources.list.d/elm.list <<<"

# .SECONDARY means that make should keep the intermediate file
.SECONDARY:

orig/amd64.gz:
	mkdir -p $(shell dirname $@)
	curl -sSL ${LIN64V19} -o $@
	@# This checks the SHA256 hash of the file.
	@# If it's not correct, the file is corrupt, so we just delete it
	sha256sum --check amd64.sha256sum || rm $@

orig/i386.gz:
	mkdir -p $(shell dirname $@)
	curl -sSL ${LIN32V19} -o $@
	@# This checks the SHA256 hash of the file.
	@# If it's not correct, the file is corrupt, so we just delete it
	sha256sum --check i386.sha256sum || rm $@

build/%/usr/bin/elm: orig/%.gz
	mkdir -p $(shell dirname $@)
	gunzip < $^ > $@
	chmod +x $@

build/%/control: control
	mkdir -p $(shell dirname $@)
	sed 's/ARCH/$*/' < $^ > $@

build/%/data.tar: build/%/usr/bin/elm
	mkdir -p $(shell dirname $@)
	@# find+touch is required to make the build deterministic (otherwise tar stores the actual mtime)
	find build/$* -exec touch -t ${RELEASE_DATE} {} \;
	@# --sort=name is required to make the build deterministic (otherwise tar uses directory order)
	tar --sort=name --owner=0 --group=0 -cf $@ -C build/$* usr

build/%/control.tar: build/%/control
	mkdir -p $(shell dirname $@)
	@# find+touch is required to make the build deterministic (otherwise tar stores the actual mtime)
	find build/$* -exec touch -t ${RELEASE_DATE} {} \;
	@# --sort=name is required to make the build deterministic (otherwise tar uses directory order)
	tar --sort=name --owner=0 --group=0 -cf $@ -C build/$* control

%.gz: %
	gzip -n < $^ > $@

build/%/debian-binary:
	mkdir -p $(shell dirname $@)
	echo 2.0 > $@

output/pool/main/e/elm/elm_0.19-1_%.deb: build/%/debian-binary build/%/control.tar.gz build/%/data.tar.gz
	mkdir -p $(shell dirname $@)
	@# D stands for deterministic
	ar Dr $@ $^ 2> /dev/null

.PHONY: clean
clean:
	rm -rf build output

build/%/Packages: build/%/control output/pool/main/e/elm/elm_0.19-1_%.deb
	mkdir -p $(shell dirname $@)
	cat build/$*/control > $@
	echo "Filename: pool/main/e/elm/elm_0.19-1_$*.deb" >> $@
	echo "Size: $(shell du -b output/pool/main/e/elm/elm_0.19-1_$*.deb | cut -f1)" >> $@
	echo "SHA256: $(shell sha256sum output/pool/main/e/elm/elm_0.19-1_$*.deb | cut -d' ' -f1)" >> $@

output/dists/stable/main/binary-%/Packages.gz: build/%/Packages
	mkdir -p $(shell dirname $@)
	gzip -n < $^ > $@

output/dists/stable/Release: output/dists/stable/main/binary-amd64/Packages.gz output/dists/stable/main/binary-i386/Packages.gz
	mkdir -p $(shell dirname $@)
	echo "Origin: Elm" > $@
	echo "Suite: stable" >> $@
	echo "Version: 0.19" >> $@
	echo "Date: ${RELEASE_DATE_HUMAN}" >> $@
	echo "Architectures: amd64 i386" >> $@
	echo "Components: main" >> $@
	echo "Description: Elm 0.19" >> $@
	echo "SHA256:" >> $@
	echo " $(shell sha256sum output/dists/stable/main/binary-amd64/Packages.gz | cut -d' ' -f1) $(shell du -b output/dists/stable/main/binary-amd64/Packages.gz | cut -f1) main/binary-amd64/Packages.gz" >> $@
	echo " $(shell sha256sum output/dists/stable/main/binary-i386/Packages.gz | cut -d' ' -f1) $(shell du -b output/dists/stable/main/binary-i386/Packages.gz| cut -f1) main/binary-i386/Packages.gz" >> $@

output/dists/stable/InRelease: output/dists/stable/Release
	gpg -a -s --clearsig < $^ > $@

output/pubkey.gpg:
	gpg --output $@ --export --armor
