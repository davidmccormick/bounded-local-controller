FROM alpine:latest
COPY bounded-local-controller /
RUN apk update &&\
apk upgrade &&\
apk add bash util-linux findutils grep &&\
chmod +x /bounded-local-controller
CMD /bounded-local-controller
