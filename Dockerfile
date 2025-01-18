# Bắt đầu từ image qemu-docker cho AMD64
FROM scratch AS build-amd64

# Sao chép tất cả tệp từ qemux/qemu-docker vào container
COPY --from=qemux/qemu-docker:6.13 / / 

# Thiết lập môi trường không có cảnh báo và chế độ không tương tác trong quá trình cài đặt
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

# Cài đặt các công cụ cần thiết
RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        bc \
        jq \
        curl \
        7zip \
        wsdd \
        samba \
        xz-utils \
        wimtools \
        dos2unix \
        cabextract \
        genisoimage \
        libxml2-utils \
        libarchive-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Sao chép tệp từ thư mục src và assets vào thư mục /run
COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

# Tải driver virtio-win từ GitHub
ADD --chmod=664 https://github.com/qemus/virtiso-whql/releases/download/v1.9.44-0/virtio-win-1.9.44.tar.xz /drivers.txz

# Khai báo và gán giá trị cho biến VERSION_ARG
ARG VERSION_ARG="latest"  # Hoặc thay "latest" bằng phiên bản cụ thể của Windows bạn muốn sử dụng

# Chuyển sang image build cho ARM64
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64

# Chuyển tiếp từ image vừa build
FROM build-${TARGETARCH}

# Cấu hình biến môi trường
ARG VERSION_ARG="0.00"
RUN echo "$VERSION_ARG" > /run/version

# Tạo thư mục /storage nếu nó chưa tồn tại
RUN mkdir -p /storage

# Đảm bảo rằng thư mục /storage có quyền đọc/ghi
RUN chmod 777 /storage

# Xác định volume cho thư mục /storage
VOLUME /storage

# Mở các cổng cần thiết cho ứng dụng
EXPOSE 8006 3389

# Cấu hình các biến môi trường
ENV VERSION="11"
ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISK_SIZE="64G"

# Đặt entrypoint cho container, sử dụng tini để quản lý quy trình
ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
