ifndef BUILD_DIR
	export BUILD_DIR=$(CURDIR)/build
endif

export VAPI_DIR=$(BUILD_DIR)/vapi
export INCLUDE_DIR=$(BUILD_DIR)/include
export LIB_DIR=$(BUILD_DIR)/lib


all:
	$(MAKE) -C archive
	$(MAKE) -C ooxml


clean:
	rm -rf $(BUILD_DIR)
