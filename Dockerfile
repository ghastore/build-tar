FROM debian:stable

LABEL "name"="CMF Package Builder"
LABEL "description"=""
LABEL "maintainer"="z17 CX <mail@z17.cx>"
LABEL "repository"="https://github.com/ghastore/cmfstore-pkg-build.git"
LABEL "homepage"="https://github.com/ghastore"

RUN apt update && apt install --yes ca-certificates

COPY sources-list /etc/apt/sources.list
COPY *.sh /
RUN apt update && apt install --yes bash curl git git-lfs rhash tar xz-utils

ENTRYPOINT ["/entrypoint.sh"]
