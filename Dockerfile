FROM alpine:latest
COPY bounded-local bounded-local-controller bounded-local-splunk /
RUN apk update &&\
apk upgrade &&\
apk add bash util-linux findutils grep curl &&\
chmod +x /bounded-local /bounded-local-controller /bounded-local-splunk &&\
mkdir -p /var/log-collection /var/lib/kubelet/bounded-local
CMD /bounded-local-controller
