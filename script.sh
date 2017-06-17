#/usr/bin/env bash

set -e

pushd $GOPATH/src/$REPO_PATH/$REPO_NAME >/dev/null 2>&1

test -n $TRAVIS_TAG && export VERSION=$TRAVIS_TAG
test -z $VERSION && export VERSION=edge
test -z $BUILD_TIME && export BUILD_TIME=$(date -u +%FT%TZ)
test -z $SHA && export SHA=$(git rev-parse HEAD 2>/dev/null)
test -z $SHORT_SHA && export SHORT_SHA=$(echo $SHA | cut -c1-7)
echo "Set VERSION to $VERSION
Set BUILD_TIME to $BUILD_TIME
Set SHA to $SHA
Set SHORT_SHA to $SHORT_SHA"

if [[ -d vendor && -f vendor/vendor.json ]]; then
    echo "Running govendor sync..."
    govendor sync
else
    echo "No vendor.json found, skipping govendor sync"
fi

echo "Creating gzipped tar file of repo..."
tar --transform "s,^\.,${REPO_NAME}-${VERSION}," --exclude .git --exclude .svn --exclude .hg -czf $HOME/rpmbuild/SOURCES/${REPO_NAME}-${VERSION}.tar.gz .

if [[ -f $REPO_NAME.spec ]]; then
    cp $REPO_NAME.spec $HOME/rpmbuild/SPECS
else
    echo "Cannot find file $REPO_NAME.spec, exiting..."
    exit;
fi

pushd $HOME/rpmbuild >/dev/null 2>&1
arch=epel-7-x86_64
mock -r $arch --init
# NOTE: --resultdir will write logs as well as RPMS to that directory
mock -r $arch --buildsrpm --source SOURCES/$REPO_NAME-$VERSION.tar.gz --no-clean --spec SPECS/$REPO_NAME.spec --resultdir $HOME/rpmbuild/SRPMS
mock -r $arch --no-clean --resultdir $HOME/rpmbuild/RPMS --rebuild $HOME/rpmbuild/SRPMS/$REPO_NAME-$VERSION-1.el7.centos.src.rpm
