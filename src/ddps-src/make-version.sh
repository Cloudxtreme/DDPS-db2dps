

git_sha=`git rev-parse HEAD`

VERSION=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`

MAJOR=`echo ${VERSION} | awk -F'.' '$1 ~ /^[0-9]+$/ { print $1 }'`
MINOR=`echo ${VERSION} | sed 's/^.*\.//; s/-.*//' | awk '$1 ~ /^[0-9]+$/ { print $1 }'`
PATCH=`echo ${VERSION} | awk -F'-' '$NF ~ /^[0-9]+$/ { print $NF }'`

VERSION="${MAJOR}.${MINOR}-${PATCH}"

cat <<-EOF > version.pm
			my \$version = "${VERSION}";
			my \$build_date = "${build_date}";
			my \$build_git_sha = "${git_sha}";
EOF
cat <<-EOF > version.c
			/* autogen by $0 on `date` */
			#include "version.h"
			const char * version = "${VERSION}";
			const char * build_date = "${build_date}";
			const char * build_git_sha = "${git_sha}";
EOF
cat <<-EOF > version.h
			/* autogen by $0 on `date` */
			#ifndef VERSION_H
			#define VERSION_H
			#define VERSION "${VERSION}"
			extern const char * build_date;		/* date +"%Y-%m-%d %H:%M" - source file last edited */
			extern const char * build_git_sha;	/* git rev-parse HEAD */
			#endif /* VERSION_H */
EOF
