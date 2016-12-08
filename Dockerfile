FROM alpine:latest
COPY bounded-local-controller /
RUN apk update &&\
apk upgrade &&\
apk add bash util-linux findutils grep &&\
chmod +x /bounded-local-controller &&\
mkdir -p /var/log-collection /var/lib/kubelet/bounded-local
CMD /bounded-local-controller