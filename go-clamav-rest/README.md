## go-clamav-rest

Clamav proxy based on https://github.com/solita/clamav-rest/ and implemented in golang

### Usage

```
Usage of go-clamav-rest:
  -host string
    	Address of the clamd instance (default "localhost")
  -listenPort int
    	TCP port that we should listen on (default 8080)
  -maxFileMem int
    	Maximum memory used to store uploaded files (excess is written to disk) (default 128)
  -port int
    	TCP port of the clamd instance (default 3310)
```
