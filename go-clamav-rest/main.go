package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/asmith030/go-clamav-rest/server"
	"github.com/sirupsen/logrus"
)

var (
	host       = flag.String("host", "localhost", "Address of the clamd instance")
	port       = flag.Int("port", 3310, "TCP port of the clamd instance")
	listenPort = flag.Int("listenPort", 8080, "TCP port that we should listen on")
	maxFileMem = flag.Int64("maxFileMem", 128, "Maximum memory used to store uploaded files (excess is written to disk)")
)

func newLogger() *logrus.Logger {
	var logger = logrus.New()
	logger.Out = os.Stderr
	jsonFormatter := new(logrus.JSONFormatter)
	jsonFormatter.TimestampFormat = time.RFC3339Nano
	logger.Formatter = jsonFormatter
	logger.Level = logrus.InfoLevel
	return logger
}

func main() {
	flag.Parse()
	logger := newLogger()

	server.RunHTTPListener(
		fmt.Sprintf("tcp://%v:%d", *host, *port),
		*listenPort, *maxFileMem, logger)
}
