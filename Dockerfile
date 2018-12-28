FROM golang:1.11.1-alpine as builder
MAINTAINER Marco Pantaleoni <marco.pantaleoni@gmail.com>

RUN apk add --update --no-cache ca-certificates git fuse

# Copy source code
RUN mkdir -p /src
WORKDIR /src
# RUN git clone git@github.com:restic/restic.git
RUN git clone https://github.com/restic/restic.git

WORKDIR /src/restic
RUN git checkout v0.9.3

# Enable Go modules
ENV GO111MODULE=on

# Build
RUN go run -mod=vendor build.go

# # Test
# RUN go test ./cmd/... ./internal/...


FROM alpine:latest
MAINTAINER Marco Pantaleoni <marco.pantaleoni@gmail.com>

RUN apk add --update --no-cache ca-certificates fuse openssh-client

# Get restic executable
ENV RESTIC_VERSION=0.9.3
# ADD https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 /
# RUN bzip2 -d restic_${RESTIC_VERSION}_linux_amd64.bz2 && mv restic_${RESTIC_VERSION}_linux_amd64 /usr/bin/restic && chmod +x /usr/bin/restic
COPY --from=builder /src/restic/restic /usr/bin/restic

RUN mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_HOST=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
# By default backup every 6 hours
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV RESTIC_INTERACTIVE=""

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY backup.sh /bin/backup
COPY entry.sh /entry.sh

RUN touch /var/log/cron.log

WORKDIR "/"

ENTRYPOINT ["/entry.sh"]
