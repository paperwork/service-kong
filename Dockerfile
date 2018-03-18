FROM paperworkco/paperplane:latest

RUN apk update \
 && apk add postgresql-client \
 && rm -rf /var/cache/apk/*

# add ContainerPilot configuration
COPY containerpilot.json5 /etc/containerpilot.json5
COPY containerpilot.sh /usr/local/bin/
RUN chmod 500 /usr/local/bin/containerpilot.sh

# Shamelessly copied from docker-kong
ENV KONG_VERSION 0.12.3
ENV KONG_SHA256 e7750f4987b7bff485387a0bc95eb51609f7abc5faea76c9598a16f1da023faa

RUN apk add --no-cache --virtual .build-deps wget tar ca-certificates \
	&& apk add --no-cache libgcc openssl pcre perl tzdata \
	&& wget -O kong.tar.gz "https://bintray.com/kong/kong-community-edition-alpine-tar/download_file?file_path=kong-community-edition-$KONG_VERSION.apk.tar.gz" \
	&& echo "$KONG_SHA256 *kong.tar.gz" | sha256sum -c - \
	&& tar -xzf kong.tar.gz -C /tmp \
	&& rm -f kong.tar.gz \
	&& cp -R /tmp/usr / \
	&& rm -rf /tmp/usr \
	&& cp -R /tmp/etc / \
	&& rm -rf /tmp/etc \
	&& apk del .build-deps
# End of copy

EXPOSE 8000 8443 8001 7946

ENTRYPOINT []
CMD ["containerpilot"]
