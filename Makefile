OCI_BUILDER_BIN ?= docker buildx

.PHONY: image
image:
	$(OCI_BUILDER_BIN) build . -t ghcr.io/sameraburabie/wireguard:local
