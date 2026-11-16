.PHONY: embed-scripts build test install uninstall

embed-scripts:
	@scripts/embed-scripts.sh

build: embed-scripts
	@scripts/build-app.sh

test: embed-scripts
	@scripts/run-tests.sh

install: build
	@scripts/install-app.sh

uninstall:
	@scripts/uninstall.sh
