FROM openshift/jenkins-slave-base-centos7

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
			org.label-schema.name="jenkins-slave-podman-ubi8" \
			org.label-schema.description="ubi8 slave podman." \
			org.label-schema.url="http://andradaprieto.es" \
			org.label-schema.vcs-ref=$VCS_REF \
			org.label-schema.vcs-url="https://github.com/jandradap/jenkins-slave-podman-ubi8" \
			org.label-schema.vendor="Jorge Andrada Prieto" \
			org.label-schema.version=$VERSION \
			org.label-schema.schema-version="1.0" \
			maintainer="Jorge Andrada Prieto <jandradap@gmail.com>"

USER root

RUN useradd build \
  && yum install -y \
      podman \
      shadow-utils \
      fuse-overlayfs /etc/containers/storage.conf \
  && yum -y clean all \
  && rm -rf /var/cache/yum \
  && rm -rf /var/cache /var/log/dnf*

# Adjust storage.conf to enable Fuse storage.
RUN sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock

# Use cgroups cgroup_manager by default (#1908567)
RUN sed -i -e '/^cgroup_manager.*/d' -e '/\#\ cgroup_manager\ =/a cgroup_manager = "cgroupfs"' /usr/share/containers/containers.conf

# workaround for rhbz#1918554
RUN sed -i -e 's|"/var/lib/shared",|#"/var/lib/shared",|' /etc/containers/storage.conf
ENV STORAGE_DRIVER=vfs

# Set up environment variables to note that this is
# not starting with usernamespace and default to
# isolate the filesystem with chroot.
ENV _BUILDAH_STARTED_IN_USERNS="" BUILDAH_ISOLATION=chroot

USER 1001