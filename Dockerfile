FROM ubuntu:16.04
MAINTAINER Marcus Jones <marcusnjones@gmail.com>

ENV GOSS_VERSION=v0.3.2

# Ensure scripts are available for use in next command
COPY ./container/root/scripts/* /scripts/

# - Symlink variant-specific scripts to default location
# - Upgrade base security packages, then clean packaging leftover
# - Add S6 for zombie reaping, boot-time coordination, signal transformation/distribution: @see https://github.com/just-containers/s6-overlay#known-issues-and-workarounds
# - Add goss for local, serverspec-like testing
RUN /bin/bash -e /scripts/ubuntu_apt_cleanmode.sh && \
    ln -s /scripts/clean_ubuntu.sh /clean.sh && \
    ln -s /scripts/security_updates_ubuntu.sh /security_updates.sh && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    /bin/bash -e /security_updates.sh && \
    apt-get install -yqq \
    wget \
    && \
    wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
    && \
    chmod +x /usr/local/bin/dumb-init \
    && \

    # Add goss for local, serverspec-like testing
    wget -O /usr/local/bin/goss https://github.com/aelsabbahy/goss/releases/download/${GOSS_VERSION}/goss-linux-amd64 \
     && \
    chmod +x /usr/local/bin/goss && \
    apt-get remove --purge -yq \
        wget \
    && \
    /bin/bash -e /clean.sh

# Overlay the root filesystem from this repo
COPY ./container/root /

# Run build-time tests
RUN goss -g goss.base.yaml validate

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
