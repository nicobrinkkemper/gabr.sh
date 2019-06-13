ARG bashver=latest

FROM bash:${bashver}

# Install parallel and accept the citation notice (we aren't using this in a
# context where it make sense to cite GNU Parallel).
RUN apk add --no-cache parallel && \
    mkdir -p ~/.parallel && touch ~/.parallel/will-cite

RUN ln -s /opt/bats/bin/bats /usr/sbin/bats
COPY ./modules/bats-core/ /opt/gabr/bats/
COPY ./gabr.sh /
COPY ./test /opt/bats
COPY ./gabr.linux.sh /

ENTRYPOINT ["bash", "/usr/sbin/bats"]