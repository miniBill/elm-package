# elm-packaged #
This project is a minimal `Makefile` to build a Debian repository for the [Elm compiler](https://elm-lang.org/).

# Build the packages #
Just run `make`.

The process will put:
* the original Release files in the `orig` directory,
* intermediate packaging files in the `build` directory,
* the output in the `output` folder:
  * `pubkey.gpg`: this is the key used to sign the repository,
  * `debian`: this folder is a valid Debian repository.
