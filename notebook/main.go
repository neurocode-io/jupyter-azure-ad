package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
)

func errHandler(res http.ResponseWriter, req *http.Request, err error) {
	fmt.Printf("Error occured: %v", err)
	http.Error(res, "Something bad happened", http.StatusBadGateway)
}

func main() {
	certPath := flag.String("cert", "", "server cert location")
	keyPath := flag.String("key", "", "private key location")
	flag.Parse()

	if *certPath == "" || *keyPath == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}

	var err error

	_, err = ioutil.ReadFile(*certPath)
	_, err = ioutil.ReadFile(*keyPath)

	if err != nil {
		log.Fatal(err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(res http.ResponseWriter, req *http.Request) {
		// AD authentication running on 8080
		downstreamURL, _ := url.Parse("http://localhost:8080")
		proxy := httputil.NewSingleHostReverseProxy(downstreamURL)
		proxy.ErrorHandler = errHandler

		proxy.ServeHTTP(res, req)

	})
	cfg := &tls.Config{
		MinVersion:               tls.VersionTLS12,
		CurvePreferences:         []tls.CurveID{tls.CurveP521, tls.CurveP384, tls.CurveP256},
		PreferServerCipherSuites: true,
		CipherSuites: []uint16{
			tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
			tls.TLS_RSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_RSA_WITH_AES_256_CBC_SHA,
		},
	}
	srv := &http.Server{
		Addr:         ":8443",
		Handler:      mux,
		TLSConfig:    cfg,
		TLSNextProto: make(map[string]func(*http.Server, *tls.Conn, http.Handler), 0),
	}
	log.Fatal(srv.ListenAndServeTLS(*certPath, *keyPath))
}
