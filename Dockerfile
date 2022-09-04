FROM alpine

LABEL "name"="TAR Package Builder"
LABEL "description"=""
LABEL "maintainer"="z17 CX <mail@z17.cx>"
LABEL "repository"="https://github.com/ghastore/store-pkg-build.git"
LABEL "homepage"="https://github.com/ghastore"

COPY *.sh /
RUN apk add --no-cache bash curl git git-lfs rhash

ENTRYPOINT ["/entrypoint.sh"]
