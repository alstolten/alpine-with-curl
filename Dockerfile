FROM alpine:3.12.0

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version="3.12.0"

RUN apk --no-cache add curl

CMD sh
