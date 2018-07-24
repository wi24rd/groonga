#!/bin/sh

set -e
set -u

: ${DOCKER:=}
: ${TARGET:=}

git submodule update --init --depth 1

if [ -n "${DOCKER}" ]; then
  curl \
    --silent \
    --location \
    https://raw.github.com/clear-code/cutter/master/data/travis/setup.sh | sh
  sudo apt-get install -qq -y \
       autotools-dev \
       autoconf-archive
  exit $?
fi

if [ -n "${TARGET}" ]; then
  ENABLE_MRUBY=yes
fi

: ${ENABLE_MRUBY:=no}

case "${TRAVIS_OS_NAME}" in
  linux)
    curl \
      --silent \
      --location \
      https://raw.github.com/clear-code/cutter/master/data/travis/setup.sh | sh
    sudo apt-get install -qq -y \
         autotools-dev \
         autoconf-archive \
         zlib1g-dev \
         libmsgpack-dev \
         libevent-dev \
         libmecab-dev \
         mecab-naist-jdic \
         cmake \
         gdb
    ;;
  osx)
    brew update > /dev/null
    brew outdated pkg-config || brew upgrade pkg-config
    brew reinstall libtool
    brew outdated libevent || brew upgrade libevent
    brew outdated pcre || brew upgrade pcre
    brew outdated msgpack || brew upgrade msgpack
    brew install \
         autoconf-archive \
         mecab \
         mecab-ipadic
    brew install --force openssl
    # brew install cutter
    ;;
esac

if [ "${ENABLE_MRUBY}" = "yes" ]; then
  gem install pkg-config groonga-client test-unit
fi
