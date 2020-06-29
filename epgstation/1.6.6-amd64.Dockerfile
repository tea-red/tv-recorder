# FFmpeg
FROM collelog/uo-ffmpeg-build:4.3-alpine-amd64 AS ffmpeg-image


# EPGStation
FROM amd64/node:12-alpine3.12 AS epgstation-build

RUN apk upgrade --update
RUN apk add --no-cache ca-certificates curl g++ make python3

RUN mkdir -p /usr/local/EPGStation
WORKDIR /usr/local/EPGStation
RUN curl -fsSL https://github.com/l3tnun/EPGStation/tarball/5dad4caf037c1cadd135c4dc2328624bd60383e4 \
		| tar -xz --strip-components=1
RUN npm install --nosave
RUN npm run build

RUN rm -rf /tmp/* /var/cache/apk/*


# JST
FROM alpine:3.12.0 as jst-image
RUN apk add tzdata
RUN echo "Asia/Tokyo" > /etc/timezone


# final image
FROM amd64/node:12-alpine3.12
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

EXPOSE 8888
EXPOSE 8889

# FFmpeg
COPY --from=ffmpeg-image /usr/local /usr/local

# EPGStation
COPY --from=epgstation-build /usr/local/EPGStation /usr/local/EPGStation

# JST
COPY --from=jst-image /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
COPY --from=jst-image /etc/timezone /etc/timezone

RUN set -eux && \
	apk upgrade --update && \
	apk add --no-cache --update \
		libgcc \
		libstdc++ \
		ca-certificates \
		libcrypto1.1 \
		libssl1.1 \
		libgomp \
		expat \
		libzmq \
		util-linux && \
	\
	# Compatible with Old Version config.json
	mkdir -p /usr/local/ffmpeg/bin && \
	ln -s /usr/local/bin/ffmpeg /usr/local/ffmpeg/bin/ffmpeg && \
	ln -s /usr/local/bin/ffprobe /usr/local/ffmpeg/bin/ffprobe && \
	\
	# cleaning
	npm cache verify && \
	rm -rf /tmp/* ~/.npm /var/cache/apk/*

WORKDIR /usr/local/EPGStation

ENTRYPOINT npm start
