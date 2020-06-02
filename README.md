# alpine-with-curl
A simple Dockerfile from alpine linux containing curl. Useful if you need to run scripts that require curl.

# builds
Builds can be found here: [alstolten/alpine-with-curl](https://hub.docker.com/r/alstolten/alpine-with-curl)

# automated
Once a day I run makerelease.sh to build if new alpine versions have been released. The latest build will be issued anyway.

# multiarch
Using [docker buildx](https://docs.docker.com/buildx/working-with-buildx/) the script builds for all docker architectures.
