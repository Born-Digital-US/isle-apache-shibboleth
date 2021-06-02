FROM islandoracollabgroup/isle-apache:1.5.7

RUN curl --fail --remote-name 'https://pkg.switch.ch/switchaai/ubuntu/dists/focal/main/binary-all/misc/switchaai-apt-source_1.0.0~ubuntu20.04.1_all.deb' && \
    apt install './switchaai-apt-source_1.0.0~ubuntu20.04.1_all.deb' && \
    SHIBB_PACKS="shibboleth \
    libapache2-mod-shib2" && \ 
    apt-get update && \
    apt-get install --install-recommends -y $SHIBB_PACKS && \
    shibd -t && \
    apache2ctl configtest && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    service shibd stop && \
    mkdir -p /var/run/shibboleth && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* '/switchaai-apt-source_1.0.0~ubuntu20.04.1_all.deb'

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE Apache Image" \
      org.label-schema.description="Primary Islandora Image." \
      org.label-schema.url="https://islandora-collaboration-group.github.io" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Collaboration-Group/isle-apache" \
      org.label-schema.vendor="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      traefik.port="80" \
      traefik.frontend.entryPoints=http,https

COPY rootfs /

EXPOSE 80

ENTRYPOINT ["/init"]
