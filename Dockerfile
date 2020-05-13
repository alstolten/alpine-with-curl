FROM alpine:3.9.6

LABEL maintainer="alstolten@gmail.com"
LABEL alpine-version="3.9.6"

RUN apk --no-cache add curl

CMD sh
