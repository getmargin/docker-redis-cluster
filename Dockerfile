# Build from commits based on redis:6
FROM redis:6.0.8

LABEL maintainer="Corey Losenegger <corey@compound.co> -- forked from Johan Andersson <Grokzen@gmail.com>"

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -yqq \
  net-tools supervisor ruby rubygems locales gettext-base wget gcc make g++ build-essential libc6-dev tcl && \
  apt-get clean -yqq

# # Ensure UTF-8 lang and locale
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Necessary for gem installs due to SHA1 being weak and old cert being revoked
ENV SSL_CERT_FILE=/usr/local/etc/openssl/cert.pem

RUN gem install redis -v 4.1.3

ARG redis_version=6.0.8

RUN wget -qO redis.tar.gz https://github.com/antirez/redis/archive/${redis_version}.tar.gz \
  && tar xfz redis.tar.gz -C / \
  && mv /redis-$redis_version /redis

RUN (cd /redis && make)

RUN mkdir /redis-conf && mkdir /redis-data

COPY redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY redis.tmpl         /redis-conf/redis.tmpl
COPY sentinel.tmpl      /redis-conf/sentinel.tmpl

# Add startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Add script that generates supervisor conf file based on environment variables
COPY generate-supervisor-conf.sh /generate-supervisor-conf.sh

RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7051 7052 7053 7054 7055 7056 7057 7058 5059 5060 5061

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]
