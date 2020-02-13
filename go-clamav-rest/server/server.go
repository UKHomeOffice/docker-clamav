package server

import (
	"fmt"
	"net"
	"net/http"

	"github.com/dutchcoders/go-clamd"
	"github.com/sirupsen/logrus"
)

func RunHTTPListener(clamd_address string, port int, max_file_mem int64, logger *logrus.Logger) error {
	m := http.NewServeMux()
	hh := &healthHandler{
		healthy: false,
		logger:  logger,
	}
	m.Handle("/healthz", hh)
	m.Handle("/", &pingHandler{
		address: clamd_address,
		logger:  logger,
	})
	m.Handle("/scan", &scanHandler{
		address:      clamd_address,
		max_file_mem: max_file_mem,
		logger:       logger,
	})
	m.Handle("/scanReply", &scanReplyHandler{
		address:      clamd_address,
		max_file_mem: max_file_mem,
		logger:       logger,
	})
	logger.Infof("Starting the webserver on port %v", port)
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return err
	}
	hh.healthy = true
	return http.Serve(lis, m)
}

type healthHandler struct {
	healthy bool
	logger  *logrus.Logger
}

func (hh *healthHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if hh.healthy {
		hh.logger.Infof("health check: ok")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Healthy\n"))
		return
	}
	hh.logger.Infof("health check: not ok")
	w.WriteHeader(http.StatusInternalServerError)
	w.Write([]byte("Unhealthy\n"))
}

type pingHandler struct {
	address string
	logger  *logrus.Logger
}

func (ph *pingHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c := clamd.NewClamd(ph.address)
	err := c.Ping()
	if err != nil {
		ph.logger.Infof("ping: not responding")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Clamd responding: false\n"))
		return
	} else {
		w.WriteHeader(http.StatusOK)
		ph.logger.Infof("ping: responding")
		w.Write([]byte("Clamd responding: true\n"))
		return
	}
}

type scanHandler struct {
	address      string
	max_file_mem int64
	logger       *logrus.Logger
}

func (sh *scanHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(sh.max_file_mem * 1024 * 1024)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	files := r.MultipartForm.File["file"]

	if len(files) == 0 {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("empty file\n"))
		return
	}

	f, err := files[0].Open()
	defer f.Close()

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	c := clamd.NewClamd(sh.address)
	response, err := c.ScanStream(f, make(chan bool))

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	result := <-response
	w.WriteHeader(http.StatusOK)
	if result.Status == "FOUND" {
		sh.logger.Infof("Scanning %v: found", files[0].Filename)
		w.Write([]byte("Everything ok : false\n"))
	} else {
		sh.logger.Infof("Scanning %v: clean", files[0].Filename)
		w.Write([]byte("Everything ok : true\n"))
	}

	return
}

type scanReplyHandler struct {
	address      string
	max_file_mem int64
	logger       *logrus.Logger
}

func (srh *scanReplyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(srh.max_file_mem * 1024 * 1024)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	files := r.MultipartForm.File["file"]

	if len(files) == 0 {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("empty file\n"))
		return
	}

	f, err := files[0].Open()
	defer f.Close()

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	c := clamd.NewClamd(srh.address)
	response, err := c.ScanStream(f, make(chan bool))

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("not okay"))
	}

	result := <-response
	w.WriteHeader(http.StatusOK)
	srh.logger.Infof("Scanning %v and returning reply", files[0].Filename)
	w.Write([]byte(result.Raw))
	return
}
