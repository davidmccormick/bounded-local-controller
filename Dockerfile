FROM alpine:latest
COPY bounded-local-controller /
RUN chmod +x /bounded-local-controller
CMD /bounded-local-controller
