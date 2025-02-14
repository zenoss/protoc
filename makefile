VERSION = 2.5.0
SOURCE_DIR = protobuf
SOURCE_ARCHIVE = protobuf-$(VERSION).tar.gz
SOURCE_PROTOC = $(SOURCE_DIR)/src/.libs/protoc

TARGET_DIR = target
TARGET_PROTOC = $(TARGET)/usr/bin/protoc

.DEFAULT_GOAL := deb

.PHONY: clean
clean:
	@rm -rf $(SOURCE_ARCHIVE) protoc*.deb $(SOURCE_DIR) $(TARGET_DIR)

.PHONY: build
build: $(SOURCE_ARCHIVE)
	docker run --rm -v $(CURDIR):/work -w /work zenoss/gcc:ubuntu2204-3 bash -c "make build-protoc"

.PHONY: build-protoc
build-protoc: $(TARGET_PROTOC)

$(SOURCE_DIR)/autogen.sh: $(SOURCE_ARCHIVE) $(SOURCE_DIR)
	tar -x --strip-components=1 -C $(SOURCE_DIR) -f $<

$(SOURCE_DIR)/Makefile: $(SOURCE_DIR)/autogen.sh
	cd $(SOURCE_DIR); ./autogen.sh; ./configure --prefix=/usr

$(SOURCE_PROTOC): $(SOURCE_DIR)/Makefile
	make -C $(SOURCE_DIR)

$(TARGET_PROTOC): $(TARGET_DIR)
$(TARGET_PROTOC): $(SOURCE_PROTOC)
	DESTDIR=/work/target make -C $(SOURCE_DIR) install

$(SOURCE_DIR) $(TARGET_DIR):
	mkdir $@

$(SOURCE_ARCHIVE):
	wget https://github.com/google/protobuf/releases/download/v2.5.0/$@

.PHONY: deb
deb: build
	docker run --rm -v $(CURDIR):/work -w /work zenoss/fpm:2 --fpm-options-file fpm_options .
