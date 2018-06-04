:

# major_version=1
# minor_version=0
# package_revision=0

git_sha=`git rev-parse HEAD 2>/dev/null`
build_date=`date +"%Y-%m-%d %H:%M"`

VERSION=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`

if [ -z "$VERSION" ]; then
    VERSION="1.0-1"
fi


MAJOR=`echo ${VERSION} | awk -F'.' '$1 ~ /^[0-9]+$/ { print $1 }'`
MINOR=`echo ${VERSION} | sed 's/^.*\.//; s/-.*//' | awk '$1 ~ /^[0-9]+$/ { print $1 }'`
PATCH=`echo ${VERSION} | awk -F'-' '$NF ~ /^[0-9]+$/ { print $NF }'`

cat <<-EOF  > version_makefile
build_date          = ${build_date}
build_git_sha       = ${git_sha}

major_version       = $MAJOR
minor_version       = $MINOR
package_revision    = $PATCH
VERSION             = ${VERSION}

EOF
