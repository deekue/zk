# Build zk in the current folder.
build:
	$(call go,build)

# Build and install `zk` using go's default bin directory.
install:
	$(call go,install)

# Run unit tests.
test:
	$(call go,test,./...)

# Run end-to-end tests.
tesh: build
	@PATH=".:$(shell pwd):$(PATH)" tesh tests tests/fixtures

# Run end-to-end tests and prints difference as raw bytes.
teshb: build
	@PATH=".:$(shell pwd):$(PATH)" tesh -b tests tests/fixtures

# Update end-to-end tests.
tesh-update: build
	PATH=".:$(shell pwd):$(PATH)" tesh -u tests tests/fixtures

# Produce a release bundle for all platforms.
dist: dist-macos dist-linux
	rm -f zk

# Produce a release bundle for macOS.
dist-macos:
	rm -f zk && make && zip -r "zk-${VERSION}-macos-`uname -m`.zip" zk

# Produce a release bundle for Linux.
dist-linux:
	rm -f zk && docker run --platform linux/amd64 --rm -v "${PWD}":/usr/src/zk -w /usr/src/zk mickaelmenu/zk-xcompile:linux-i386 /bin/bash -c 'make' && tar -zcvf "zk-${VERSION}-linux-i386.tar.gz" zk
	rm -f zk && docker run --platform linux/amd64 --rm -v "${PWD}":/usr/src/zk -w /usr/src/zk mickaelmenu/zk-xcompile:linux-amd64 /bin/bash -c 'make' && tar -zcvf "zk-${VERSION}-linux-amd64.tar.gz" zk
	rm -f zk && docker run --platform linux/amd64 --rm -v "${PWD}":/usr/src/zk -w /usr/src/zk mickaelmenu/zk-xcompile:linux-arm64 /bin/bash -c 'make' && tar -zcvf "zk-${VERSION}-linux-arm64.tar.gz" zk

# Clean build products.
clean:
	rm -rf zk*


VERSION := `git describe --tags --match v[0-9]* 2> /dev/null`
BUILD := `git rev-parse --short HEAD`

ENV_PREFIX := CGO_ENABLED=1
# Add necessary env variables for Apple Silicon.
ifeq ($(shell uname -sm),Darwin arm64)
	ENV_PREFIX := $(ENV) GOARCH=arm64
endif

# Wrapper around the go binary, to set all the default parameters.
define go
	$(ENV_PREFIX) go $(1) -tags "fts5" -ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)" $(2)
endef

