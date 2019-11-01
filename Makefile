URL_FOR_elm_0.19.0-1_i386.gz := "https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz"
DATE_FOR_elm_0.19.0-1_i386 := "2018-08-21T11:46:00Z"

URL_FOR_elm_0.19.0-1_amd64.gz := "https://github.com/elm/compiler/releases/download/0.19.0/binary-for-linux-64-bit.gz"
DATE_FOR_elm_0.19.0-1_amd64 := "2018-08-21T11:46:00Z"

URL_FOR_elm_0.19.1-1_amd64.gz := "https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz"
DATE_FOR_elm_0.19.1-1_amd64 := "2019-10-21T12:12:00Z"

URL_FOR_elm-format_0.8.2-1_amd64.tgz="https://github.com/avh4/elm-format/releases/download/0.8.2/elm-format-0.8.2-linux-x64.tgz"
DATE_FOR_elm-format_0.8.2-1_amd64="2019-08-09T06:05:00Z"

PACKAGES=elm_0.19.0-1_i386 elm_0.19.0-1_amd64 elm_0.19.1-1_amd64 elm-format_0.8.2-1_amd64

RELEASE_DATE=$(shell TZ=UTC LANG=C date -R -u -d $(DATE_FOR_elm_0.19.1-1_amd64))

.PHONY: all
all: output/debian/Packages output/debian/Packages.gz output/debian/InRelease output/pubkey.gpg $(foreach PACKAGE,$(PACKAGES),output/debian/$(PACKAGE).deb)
	@echo ">>> sudo apt-key add output/pubkey.gpg <<<"
	@echo ">>> echo "deb http:/.../debian/ ./" | sudo tee /etc/apt/sources.list.d/elm.list <<<"
	@echo ">>> sudo apt install elm elm-format <<<"

# .SECONDARY means that make should keep the intermediate files
.SECONDARY:

# Download and check SHA256
orig/%:
	mkdir -p $(shell dirname $@)
	curl -sSL $(URL_FOR_$*) -o $@
	@# This checks the SHA256 hash of the file.
	@# If it's not correct, the file is corrupt, so we just delete it
	sha256sum --check checksums/$*.sha256sum || rm $@

build/%/usr/bin/elm: orig/%.gz
	mkdir -p $(shell dirname $@)
	pigz -d < $^ > $@
	chmod +x $@

build/%/usr/bin/elm-format: orig/%.tgz
	mkdir -p $(shell dirname $@)
	tar xf $^ -C $(shell dirname $@)
	chmod +x $@

build/%/control: src/%/control
	mkdir -p $(shell dirname $@)
	cp $^ $@

build/elm_%/data.tar: build/elm_%/usr/bin/elm
	mkdir -p $(shell dirname $@)
	@# --sort=name is required to make the build deterministic (otherwise tar uses directory order)
	tar --sort=name --mtime=$(DATE_FOR_elm_$*) --owner=0 --group=0 --numeric-owner -cf $@ -C build/elm_$* usr

build/elm-format_%/data.tar: build/elm-format_%/usr/bin/elm-format
	mkdir -p $(shell dirname $@)
	@# --sort=name is required to make the build deterministic (otherwise tar uses directory order)
	tar --sort=name --mtime=$(DATE_FOR_elm_format_$*) --owner=0 --group=0 --numeric-owner -cf $@ -C build/elm-format_$* usr

build/%/control.tar: build/%/control
	mkdir -p $(shell dirname $@)
	@# --sort=name is required to make the build deterministic (otherwise tar uses directory order)
	tar --sort=name --mtime=$(DATE_FOR_$*) --owner=0 --group=0 --numeric-owner -cf $@ -C build/$* control

%.gz: %
	mkdir -p $(shell dirname $@)
	pigz -9 -n < $^ > $@

build/debian-binary:
	mkdir -p $(shell dirname $@)
	echo 2.0 > $@

output/debian/%.deb: build/debian-binary build/%/control.tar.gz build/%/data.tar.gz
	mkdir -p $(shell dirname $@)
	@# D stands for deterministic
	ar Dr $@ $^ 2> /dev/null

.PHONY: clean
clean:
	rm -rf build output

define packageInfo
echo "" >> $@
cat build/$(1)/control >> $@
echo "Filename: $(1).deb" >> $@
echo "Size: $(shell du -b output/debian/$(1).deb | cut -f1)" >> $@
echo "SHA256: $(shell sha256sum output/debian/$(1).deb | cut -d' ' -f1)" >> $@

endef

output/debian/Packages: $(foreach PACKAGE,$(PACKAGES), build/$(PACKAGE)/control output/debian/${PACKAGE}.deb)
	mkdir -p $(shell dirname $@)
	truncate -s 0 $@
	$(foreach PACKAGE,$(PACKAGES),$(call packageInfo,$(PACKAGE)))

build/Release: output/debian/Packages output/debian/Packages.gz
	mkdir -p $(shell dirname $@)
	echo "Origin: Elm" > $@
	echo "Date: $(RELEASE_DATE)" >> $@
	echo "Architectures: amd64 i386" >> $@
	echo "Description: Elm and related utilities" >> $@
	echo "SHA256:" >> $@
	echo " $(shell sha256sum output/debian/Packages | cut -d' ' -f1) $(shell du -b output/debian/Packages | cut -f1) Packages" >> $@
	echo " $(shell sha256sum output/debian/Packages.gz | cut -d' ' -f1) $(shell du -b output/debian/Packages.gz | cut -f1) Packages.gz" >> $@

output/debian/InRelease: build/Release
	mkdir -p $(shell dirname $@)
	gpg -a -s --clearsig < $^ > $@

output/pubkey.gpg:
	mkdir -p $(shell dirname $@)
	gpg --output $@ --export --armor
