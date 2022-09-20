FROM alpine

LABEL "name"="TAR Builder"
LABEL "description"=""
LABEL "maintainer"="z17 Development <mail@z17.dev>"
LABEL "repository"="https://github.com/ghastore/store-pkg-build.git"
LABEL "homepage"="https://github.com/ghastore"

COPY *.sh /
RUN apk add --no-cache bash curl git git-lfs rhash xz

ENTRYPOINT ["/entrypoint.sh"]
