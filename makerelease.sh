#!/bin/bash

set -Eeuo pipefail
# Get latest difference of tags
RELEASE_LIST=`comm <(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/alpine/tags?page_size=20' | jq '."results"[]["name"]' -r | grep -E "[0-9]\.[0-9]{1,2}\.[0-9]{1,2}" | sort) <(curl -L -s 'https://registry.hub.docker.com/v2/repositories/alstolten/alpine-with-curl/tags?page_size=20' | jq '."results"[]["name"]' -r | grep -E "[0-9]\.[0-9]{1,2}\.[0-9]{1,2}" | sort) -3`

# If difference in tag list, then build. Use multiarch
if [ -n "$RELEASE_LIST" ]; then
	while IFS= read -r line; do
		docker buildx build --progress plain --no-cache \
			--platform linux/amd64,linux/386,linux/arm64,linux/ppc64le,linux/s390x,linux/arm \
			-t alstolten/alpine-with-curl:$line --push -<<EOF
FROM alpine:$line

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version=$line

RUN apk --no-cache add curl

CMD sh
EOF
	done <<< "$RELEASE_LIST"
fi

# Make latest release anyway
docker buildx build --progress plain --no-cache \
       	--platform linux/amd64,linux/386,linux/arm64,linux/ppc64le,linux/s390x,linux/arm \
	-t alstolten/alpine-with-curl:latest --push -<<EOF
FROM alpine:latest

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version=latest

RUN apk --no-cache add curl

CMD sh
EOF

# Prune build cache
docker buildx prune -af
