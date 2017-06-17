# golang-rpmbuild [![Build Status](https://travis-ci.org/goption/golang-rpmbuild.svg?branch=develop)](https://travis-ci.org/goption/golang-rpmbuild)
A Dockerfile to build and optionally sign Golang RPMs using Mock

## Usage
This file is designed to be extended (see [Building RPMS](#building-rpms))
and run noninteractively. The ENTRYPOINT, script.sh, sets a few
basic variables that can be referenced in the spec file:
- VERSION: searches for TRAVIS_TAG, defaults to edge
- BUILD_TIME: defaults to ISO-8601 of now
- SHA: ala `git rev-parse HEAD`
- SHORT_SHA: `cut c1-7` version of SHA

It will also run `govendor sync` if vendor/vendor.json is present.

**When you run from this file, be sure to specify `--cap-add=SYS_ADMIN`
because otherwise Mock will eat it.**

### Building RPMs
Extend this file by adding your Gocode to the appropriate directory under
the `$GOPATH` and telling the ENTRYPOINT script where to find it:
```Dockerfile
FROM goption/golang-rpmbuild

ADD <repo> $GOPATH/src/<repo_path>/<repo>
ENV REPO_PATH <repo_path> # (eg github.com/user)
ENV REPO_NAME <repo> # (eg myproject)
```
The variables are very important, as the ENTRYPOINT script reads
`pushd $GOPATH/src/$REPO_PATH/$REPO_NAME`. You should be able to run your
built Dockerfile from there and wind up with RPM's in /root/rpmbuild/RPMS.

Mock is currently setup to build RPMs for EL7 only. It will try to build
debug RPMs, so either give your binary an RPM-friendly buildid
(NOT `go build -ldflags "-buildid ..."`) or `%define debug_package %{nil}`
in your specfile.

Since there is no provision to read the `release` variable from the spec file
and Mock needs the name of the SRPM to build the RPM, it will always look for
1.el7 in the SRPM filename: `$REPO_NAME-$VERSION-1.el7.centos.src.rpm`, and
the RPM will be identically named but without the `.src`. **If you specify a
release other than `1%{dist}`, it will not work.**

### Signing RPMs
Add a few more options to your Dockerfile:
```Dockerfile
ENV KEYNAME="my-pk-name" PASSPHRASE="something"
ADD my-private-key.asc /root/my-pk-name.asc
```
In order to sign the RPM, the `KEYNAME` variable and a file in /root
(technically $HOME, see above) called `$KEYNAME.asc` are necessary.

If the `PASSPHRASE` variable is defined, Expect will provide it to Mock
(which runs `rpmsign`).

### Running as a Regular User
Note that while the script references root's home directory via `$HOME`,
it will not run as another user out of the box:
- The Dockerfile runs `rpmdev-setuptree`, which of course runs as root, but
the script adds the appropriate lines for `rpmsign` (gpg stuff) to
`$HOME/.rpmmacros`.
- `rpm --import` (or `rpmkeys --import`) needs to be run as root
- Mock needs to run as root, but will prompt for a root password if run
as a regular user. Additionally, all of the configuration additions and
changes for Mock are stored in /root/.config/mock.cfg
(from mock.cfg in this directory)

With a bit of magic from our friend Expect, this can all be done.
