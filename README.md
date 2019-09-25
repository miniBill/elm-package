# elm-packaged #
This project is a minimal `Makefile` to build installable `.deb` files for the [Elm compiler](https://elm-lang.org/).

# Build the packages #
Just run `make`.

The process will put:
* the original Release files in the `orig` directory,
* intermediate packaging files in the `build` directory (this is cleaned by `make clean`),
* the output `deb`s (32 and 64 bit) in the `output` folder.
