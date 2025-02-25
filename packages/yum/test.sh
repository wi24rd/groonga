#!/bin/bash

set -exu

os=$(cut -d: -f4 /etc/system-release-cpe)
case ${os} in
  centos)
    version=$(cut -d: -f5 /etc/system-release-cpe)
    ;;
  *) # For AlmaLinux
    version=$(cut -d: -f5 /etc/system-release-cpe | sed -e 's/\.[0-9]$//')
    ;;
esac

case ${version} in
  7)
    DNF=yum
    ;;
  *)
    DNF="dnf --enablerepo=powertools"
    ;;
esac

${DNF} install -y \
  https://packages.groonga.org/centos/groonga-release-latest.noarch.rpm

repositories_dir=/groonga/packages/yum/repositories
${DNF} install -y \
  ${repositories_dir}/${os}/${version}/$(arch)/Packages/*.rpm

groonga --version
if ! groonga --version | grep -q apache-arrow; then
  echo "Apache Arrow isn't enabled"
  exit 1
fi

run_test=yes
case $(arch) in
  aarch64)
    run_test=no
    ;;
esac

if [ "${run_test}" = "yes" ]; then
  mkdir -p /test
  cd /test
  cp -a /groonga/test/command ./

  case ${version} in
    7)
      ${DNF} install -y centos-release-scl-rh
      ${DNF} install -y rh-ruby30-ruby-devel
      set +u
      . /opt/rh/rh-ruby30/enable
      set -u
      ;;
    *)
      ${DNF} install -y ruby-devel
      ;;
  esac

  ${DNF} install -y \
    gcc \
    make \
    redhat-rpm-config
  MAKEFLAGS=-j$(nproc) gem install grntest

  export TZ=Asia/Tokyo

  grntest_options=()
  grntest_options+=(--base-directory=command)
  grntest_options+=(--n-retries=3)
  grntest_options+=(--n-workers=$(nproc))
  grntest_options+=(--reporter=mark)
  grntest_options+=(command/suite)

  grntest "${grntest_options[@]}"
  grntest "${grntest_options[@]}" --interface http
  grntest "${grntest_options[@]}" --interface http --testee groonga-httpd
fi

# Should not block system update
${DNF} update -y
