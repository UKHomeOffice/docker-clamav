FROM golang:1.13 as builder

WORKDIR /go/src/github.com/asmith030/go-clamav-rest

COPY go.mod go.sum main.go ./

COPY server/  ./server/

RUN CGO_ENABLED=0 GOOS=linux go install -v \
            github.com/asmith030/go-clamav-rest

FROM alpine:3.11.3
RUN apk --no-cache add ca-certificates

RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

USER 1000

COPY --from=builder /go/bin/go-clamav-rest /go-clamav-rest

EXPOSE 8080

ENTRYPOINT ["/go-clamav-rest"]
