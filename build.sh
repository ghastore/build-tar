#!/bin/bash -e

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION.
# -------------------------------------------------------------------------------------------------------------------- #

# Vars.
GIT_REPO_SRC="${1}"
GIT_REPO_DST="${2}"
GIT_USER="${3}"
GIT_EMAIL="${4}"
GIT_TOKEN="${5}"

# Apps.
date="$( command -v date )"
git="$( command -v git )"
mv="$( command -v mv )"
rm="$( command -v rm )"
tar="$( command -v tar )"
tee="$( command -v tee )"
sum="$( command -v sha256sum )"
ts="$( _timestamp )"
ver="$( _version )"

# Dirs.
d_src="/root/git/repo_src"
d_dst="/root/git/repo_dst"

# Git config.
${git} config --global user.name "${GIT_USER}"
${git} config --global user.email "${GIT_EMAIL}"
${git} config --global init.defaultBranch 'main'

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZATION.
# -------------------------------------------------------------------------------------------------------------------- #

init() {
  git_clone \
    && ( ( pkg_orig_pack && pkg_src_build && pkg_src_move ) 2>&1 ) | ${tee} "${d_src}/build.log" \
    && git_push \
    && obs_upload \
    && obs_trigger
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: CLONE REPOSITORIES.
# -------------------------------------------------------------------------------------------------------------------- #

git_clone() {
  echo "--- [GIT] CLONE: ${GIT_REPO_SRC#https://} & ${GIT_REPO_DST#https://}"

  SRC="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_SRC#https://}"
  DST="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_DST#https://}"

  ${git} clone "${SRC}" "${d_src}" \
    && ${git} clone "${DST}" "${d_dst}"

  echo "--- [GIT] LIST: '${d_src}'"
  ls -1 "${d_src}"

  echo "--- [GIT] LIST: '${d_dst}'"
  ls -1 "${d_dst}"
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: PACKING FILES.
# -------------------------------------------------------------------------------------------------------------------- #

pkg_orig_pack() {
  echo "--- [SYSTEM] PACKING"
  _pushd "${d_src}" || exit 1

  # Set package version.
  PKG_VER="${ver}"
  SOURCE="*"
  TARGET="${OBS_PACKAGE}.${PKG_VER}.tar.xz"
  ${tar} -cJf "${TARGET}" "${SOURCE}"
  echo "File '${TARGET}' created!"

  ${sum} "${TARGET}" > "${TARGET}.sha256"

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: MOVE PACKAGE TO CMF PACKAGE STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

pkg_src_move() {
  echo "--- [SYSTEM] MOVE: '${d_src}' -> '${d_dst}'"

  # Remove old files from 'd_dst'.
  echo "Removing old files from repository..."
  ${rm} -fv "${d_dst}"/*

  # Move new files from 'd_src' to 'd_dst'.
  echo "Moving new files to repository..."
  for i in README.md LICENSE *.tar.* *.log; do
    ${mv} -fv "${d_src}"/${i} "${d_dst}" || exit 1
  done
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: PUSH PACKAGE TO DEBIAN PACKAGE STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

git_push() {
  echo "--- [GIT] PUSH: '${d_dst}' -> '${GIT_REPO_DST#https://}'"
  _pushd "${d_dst}" || exit 1

  # Commit build files & push.
  echo "Commit build files & push..."
  ${git} add . \
    && ${git} commit -a -m "BUILD: ${ts}" \
    && ${git} push

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# ------------------------------------------------< COMMON FUNCTIONS >------------------------------------------------ #
# -------------------------------------------------------------------------------------------------------------------- #

# Pushd.
_pushd() {
  command pushd "$@" > /dev/null || exit 1
}

# Popd.
_popd() {
  command popd > /dev/null || exit 1
}

# Timestamp.
_timestamp() {
  ${date} -u '+%Y-%m-%d %T'
}

# Pkg version.
_version() {
  ${date} -u '+%Y-%m-%d.%H-%M-%S'
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

init "$@"; exit 0
