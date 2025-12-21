## Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build /build
COPY rootfs /rootfs

## Base Image
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10
FROM quay.io/fedora/fedora-bootc:latest

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

## Modifications
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/build.sh

# RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
#     --mount=type=tmpfs,dst=/var \
#     --mount=type=tmpfs,dst=/tmp \
#     /ctx/build/build.sh


#     RUN rm -rf /opt && ln -s /var/opt /opt
COPY --chown=1000:1000 /nix /var/nix
RUN rm -rf /nix && ln -s /var/nix /nix

## Linting (Verify final image and content correctness)
RUN ostree container commit && bootc container lint
