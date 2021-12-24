#!/bin/bash

# error handling
set -Eeuo pipefail
GLOBAL_EXIT=0

# Logging
APP=docker-builder
echo "Starting build of alpine-with-curl..." | systemd-cat -t $APP -p info
LOG=/var/log/docker-builder.log
function log-unexpected-exit()
{
	echo "Unexpected exit." | systemd-cat -t $APP -p err
}
trap log-unexpected-exit ERR


# Get latest difference of tags
NEW_RELEASES=$(comm -23 <(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags?page_size=20' | jq '."results"[]["name"]' -r | grep -E "[0-9]\.[0-9]{1,2}\.[0-9]{1,2}" | sort) <(curl -L -s 'https://registry.hub.docker.com/v2/repositories/alstolten/alpine-with-curl/tags?page_size=20' | jq '."results"[]["name"]' -r | grep -E "[0-9]\.[0-9]{1,2}\.[0-9]{1,2}" | sort))

# If difference in tag list, then build. Use multiarch
if [ -n "$NEW_RELEASES" ]; then
	while IFS= read -r line; do
		docker buildx build --progress plain --no-cache \
			--platform linux/amd64,linux/386,linux/arm64,linux/ppc64le,linux/s390x,linux/arm \
			-t alstolten/alpine-with-curl:$line --push &>> $LOG -<<EOF
FROM alpine:$line

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version=$line

RUN apk --no-cache add curl

CMD sh
EOF
	done <<< "$NEW_RELEASES"
	if [ $? -ne 0 ]; then
		GLOBAL_EXIT=$?
	fi
fi

# Make latest release anyway
docker buildx build --progress plain --no-cache \
       	--platform linux/amd64,linux/386,linux/arm64,linux/ppc64le,linux/s390x,linux/arm \
	-t alstolten/alpine-with-curl:latest --push &>> $LOG -<<EOF
FROM alpine:latest

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version=latest

RUN apk --no-cache add curl

CMD sh
EOF
if [ $? -ne 0 ]; then
	GLOBAL_EXIT=$?
fi

# Prune build cache
docker buildx prune -af
if [ $? -ne 0 ]; then
	GLOBAL_EXIT=$?
fi

if [ $GLOBAL_EXIT -ne 0 ]; then
	echo "Finished with warnings/errors, see $LOG for details." | tee >(systemd-cat -t $APP -p warning) >(sendmail <email>)
else
	echo "Finished successfully." | systemd-cat -t $APP -p info
fi

