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
hash="$( command -v rhash )"
mkdir="$( command -v mkdir )"
mv="$( command -v mv )"
rm="$( command -v rm )"
sum="$( command -v sha256sum )"
tar="$( command -v tar )"

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
  # Functions.
  ts="$( _timestamp )"
  ver="$( _version )"

  # Run.
  git_clone \
    && tar_pack \
    && tar_move \
    && tar_sum \
    && git_push
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: CLONE REPOSITORIES.
# -------------------------------------------------------------------------------------------------------------------- #

git_clone() {
  echo "--- [GIT] CLONE: ${GIT_REPO_SRC#https://} & ${GIT_REPO_DST#https://}"

  local src="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_SRC#https://}"
  local dst="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_DST#https://}"

  ${git} clone "${src}" "${d_src}" \
    && ${git} clone "${dst}" "${d_dst}"

  echo "--- [GIT] LIST: '${d_src}'"
  ls -1 "${d_src}"

  echo "--- [GIT] LIST: '${d_dst}'"
  ls -1 "${d_dst}"
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: PACKING FILES.
# -------------------------------------------------------------------------------------------------------------------- #

tar_pack() {
  echo "--- [SYSTEM] PACKING"
  _pushd "${d_src}" || exit 1

  # Set TAR version.
  local tar_ver="${ver}"
  local tar_dir; tar_dir="$( echo "${GIT_REPO_DST}" | awk -F '[/.]' '{ print $6 }' )_${tar_ver}"
  local tar_name="${tar_dir}.tar.xz"

  ${mkdir} -p "${tar_dir}" \
    && ${mv} -f "*" "${tar_dir}"
  ${tar} -cJf "${tar_name}" "${tar_dir}"
  ${sum} "${tar_name}" > "${tar_name}.sha256"

  echo "${tar_dir} /// ${tar_name}"

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: MOVE TAR TO TAR STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

tar_move() {
  echo "--- [SYSTEM] MOVE: '${d_src}' -> '${d_dst}'"

  # Remove old files from 'd_dst'.
  echo "Removing old files from repository..."
  ${rm} -fv "${d_dst}"/*

  # Move new files from 'd_src' to 'd_dst'.
  echo "Moving new files to repository..."
  for i in README.md LICENSE *.tar.*; do
    ${mv} -fv "${d_src}"/${i} "${d_dst}" || exit 1
  done
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: CHECKSUM.
# -------------------------------------------------------------------------------------------------------------------- #

tar_sum() {
  echo "--- [HASH] CHECKSUM FILES"
  _pushd "${d_dst}" || exit 1

  for i in *; do
    echo "Checksum '${i}'..."
    [[ -f "${i}" ]] && ${hash} -u "${OBS_PACKAGE}.sha3-256" --sha3-256 "${i}"
  done

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: PUSH TAR TO TAR STORE REPOSITORY.
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

# TAR version.
_version() {
  ${date} -u '+%Y-%m-%d.%H-%M-%S'
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

init "$@"; exit 0
