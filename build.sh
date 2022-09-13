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
NAME="$( echo "${GIT_REPO_DST}" | awk -F '[/.]' '{ print $6 }' )"

# Apps.
cp="$( command -v cp )"
date="$( command -v date )"
git="$( command -v git )"
hash="$( command -v rhash )"
mkdir="$( command -v mkdir )"
mv="$( command -v mv )"
rm="$( command -v rm )"
sleep="$( command -v sleep )"
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
  ts_date="$( _ts_date )"
  ts_ver="$( _ts_ver )"

  # Run.
  clone \
    && pack \
    && move \
    && sum \
    && push
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: CLONE REPOSITORIES.
# -------------------------------------------------------------------------------------------------------------------- #

clone() {
  echo "--- [GIT] CLONE: ${GIT_REPO_SRC#https://} & ${GIT_REPO_DST#https://}"

  local src="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_SRC#https://}"
  local dst="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_DST#https://}"

  ${git} clone "${src}" "${d_src}" \
    && ${git} clone "${dst}" "${d_dst}"

  if [[ -d "${d_src}" ]] && [[ "$( ls -a ${d_src} )" ]]; then
    echo "--- [GIT] LIST: '${d_src}'"; ls -1 "${d_src}"
  else
    echo "ERROR: Directory ${d_src} not exist or empty!"
    exit 1
  fi

  if [[ -d "${d_dst}" ]] && [[ "$( ls -a ${d_dst} )" ]]; then
    echo "--- [GIT] LIST: '${d_dst}'"; ls -1 "${d_dst}"
  else
    echo "ERROR: Directory ${d_dst} not exist or empty!"
    exit 1
  fi

  ${sleep} 2
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: PACKING FILES.
# -------------------------------------------------------------------------------------------------------------------- #

pack() {
  echo "--- [SYSTEM] PACKING"
  _pushd "${d_src}" || exit 1

  # Set TAR version.
  local dir="${NAME}.${ts_ver}"
  local name="${dir}.tar.xz"

  ${mkdir} -p "${dir}" \
    && ${cp} -RT . "${dir}"
  ${tar} -cJf "${name}" "${dir}"

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: MOVE TAR TO TAR STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

move() {
  echo "--- [SYSTEM] MOVE: '${d_src}' -> '${d_dst}'"

  # Remove old files from 'd_dst'.
  echo "Removing old files from repository..."
  ${rm} -fv "${d_dst}"/*

  # Move new files from 'd_src' to 'd_dst'.
  echo "Moving new files to repository..."
  for i in README.md LICENSE *.tar.*; do
    ${mv} -fv "${d_src}"/${i} "${d_dst}" || exit 1
  done

  # Copy GitHub Action 'mirror.yml' from 'd_src' to 'd_dst'.
  echo "Copy GitHub Action 'mirror.yml' to repository..."
  ${mkdir} -p "${d_dst}/.github/workflows" \
    && ${cp} "${d_src}/.github/workflows/mirror.yml" "${d_dst}/.github/workflows/"
}

# -------------------------------------------------------------------------------------------------------------------- #
# SYSTEM: CHECKSUM.
# -------------------------------------------------------------------------------------------------------------------- #

sum() {
  echo "--- [HASH] CHECKSUM FILES"
  _pushd "${d_dst}" || exit 1

  for i in *; do
    echo "Checksum '${i}'..."
    [[ -f "${i}" ]] && ${hash} -u "${NAME}.${ts_ver}.sha3-256" --sha3-256 "${i}"
  done

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: PUSH TAR TO TAR STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

push() {
  echo "--- [GIT] PUSH: '${d_dst}' -> '${GIT_REPO_DST#https://}'"
  _pushd "${d_dst}" || exit 1

  # Commit build files & push.
  echo "Commit build files & push..."
  push_response=1; push_attempt=1

  until [[ ${push_response} -eq 0 ]] || [[ ${push_attempt} -gt 5 ]]; do
    ${git} add . \
      && ${git} commit -a -m "BUILD: ${ts_date}" \
      && ${git} push

    push_response=$?; push_attempt=$(( push_attempt + 1 ))
    [[ ${push_response} -ne 0 ]] && ${sleep} 5
  done

  # Exit if git push error.
  if [[ ${push_response} -ne 0 ]] && [[ ${push_attempt} -gt 5 ]]; then
    echo "ERROR: Git push error!"
    exit ${push_response}
  fi

  ${sleep} 2; _popd || exit 1
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

# Timestamp: Date.
_ts_date() {
  ${date} -u '+%Y-%m-%d %T'
}

# Timestamp: Version.
_ts_ver() {
  ${date} -u '+%Y-%m-%d.%H-%M-%S'
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

init "$@"; exit 0
