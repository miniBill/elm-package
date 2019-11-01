# elm-packaged #
This project is a minimal `Makefile` to build a Debian repository for the [Elm compiler](https://elm-lang.org/).

# Build the packages #
Just run `make -j`.

The process will put:
* the original Release files in the `orig` directory,
* intermediate packaging files in the `build` directory,
* the output in the `output` folder:
  * `pubkey.gpg`: this is the key used to sign the repository,
  * `debian`: this folder is a valid Debian repository.

# Repository usage - Debian, Ubuntu, derivatives #
To test the resulting repository locally, just add it:
```
sudo apt-key add output/pubkey.gpg
echo deb http:/localhost:8000/debian/ ./ | sudo tee /etc/apt/sources.list.d/elm.list
```
serve it:
```
cd output
python -m SimpleHTTPServer
```
and then you can use it:
```
sudo apt-get update
sudo apt install elm elm-format
```
