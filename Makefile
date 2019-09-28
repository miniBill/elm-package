
LIN64V19="https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz"
SHA64="d359adbee89823c641cda326938708d7227dc79aa1f162e0d8fe275f182f528a"

LIN32V19="https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
SHA32="7a82bbf34955960d9806417f300e7b2f8d426933c09863797fe83b67063e0139"

RELEASE_DATE="201808211146"
RELEASE_DATE_HUMAN=$(shell TZ=UTC LANG=C date -R -u -d 2018-08-21T11:46:00)

.PHONY: all
all: output/debian/InRelease output/pubkey.gpg
	@echo ">>> sudo apt-key add output/pubkey.gpg <<<"
	@echo ">>> echo "deb http:/.../debian/ ./" | sudo tee /etc/apt/sources.list.d/elm.list <<<"

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

build/debian-binary:
	mkdir -p $(shell dirname $@)
	echo 2.0 > $@

output/debian/elm_0.19-1_%.deb: build/debian-binary build/%/control.tar.gz build/%/data.tar.gz
	mkdir -p $(shell dirname $@)
	@# D stands for deterministic
	ar Dr $@ $^ 2> /dev/null

.PHONY: clean
clean:
	rm -rf build output

output/debian/Packages: build/i386/control output/debian/elm_0.19-1_i386.deb build/amd64/control output/debian/elm_0.19-1_amd64.deb
	mkdir -p $(shell dirname $@)

	cat build/i386/control > $@
	echo "Filename: elm_0.19-1_i386.deb" >> $@
	echo "Size: $(shell du -b output/debian/elm_0.19-1_i386.deb | cut -f1)" >> $@
	echo "SHA256: $(shell sha256sum output/debian/elm_0.19-1_i386.deb | cut -d' ' -f1)" >> $@

	echo "" > $@

	cat build/amd64/control > $@
	echo "Filename: elm_0.19-1_amd64.deb" >> $@
	echo "Size: $(shell du -b output/debian/elm_0.19-1_amd64.deb | cut -f1)" >> $@
	echo "SHA256: $(shell sha256sum output/debian/elm_0.19-1_amd64.deb | cut -d' ' -f1)" >> $@

output/debian/Packages.gz: output/debian/Packages
	mkdir -p $(shell dirname $@)
	gzip -n < $^ > $@

build/Release: output/debian/Packages output/debian/Packages.gz
	mkdir -p $(shell dirname $@)
	echo "Origin: Elm" > $@
	echo "Version: 0.19" >> $@
	echo "Date: ${RELEASE_DATE_HUMAN}" >> $@
	echo "Architectures: amd64 i386" >> $@
	echo "Description: Elm 0.19" >> $@
	echo "SHA256:" >> $@
	echo " $(shell sha256sum output/debian/Packages | cut -d' ' -f1) $(shell du -b output/debian/Packages | cut -f1) Packages" >> $@
	echo " $(shell sha256sum output/debian/Packages.gz | cut -d' ' -f1) $(shell du -b output/debian/Packages.gz | cut -f1) Packages.gz" >> $@

output/debian/InRelease: build/Release
	mkdir -p $(shell dirname $@)
	gpg -a -s --clearsig < $^ > $@

output/pubkey.gpg:
	mkdir -p $(shell dirname $@)
	gpg --output $@ --export --armor
