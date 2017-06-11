# golang-rpmbuild [![Build Status](https://travis-ci.org/goption/golang-rpmbuild.svg?branch=develop)](https://travis-ci.org/goption/golang-rpmbuild)
A Docker setup to build Golang RPMs using Mock

## Usage
This file will not work by itself, as there is nothing to actually add in
any code. You will need to create a Dockerfile with
`FROM goption/golang-rpmbuild` and make sure it contains three things:
- `ADD <repo> $GOPATH/src/<repo_path>/<repo>`
- `ENV REPO_PATH <repo_path>` (eg github.com/user)
- `ENV REPO_NAME <repo>` (eg myproject)
These three variables are very important, as the first line of the
ENTRYPOINT script is `pushd $GOPATH/src/$REPO_PATH/$REPO_NAME >/dev/null 2>&1`.

When you run this file, be sure to specify `--cap-add=SYS_ADMIN` because
otherwise Mock will eat it, as it creates a chroot.
