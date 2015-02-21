ifndef BUILD_DIR
	export BUILD_DIR=$(CURDIR)/build
endif

ifeq ($(BUILD), win32)
	CC = i686-w64-mingw32-gcc
	AR = i686-w64-mingw32-ar
	LD = i686-w64-mingw32-ld
	PKGCONFIG = i686-w64-mingw32-pkg-config
	FLAGS = \
		--cc=$(CC) \
		--pkg-config=$(PKGCONFIG) \
		-D WINDOWS
	BINEXT = .exe
	LIBEXT = lib
else ifeq ($(BUILD), win64)
	CC = x86_64-w64-mingw32-gcc
	AR = x86_64-w64-mingw32-ar
	LD = x86_64-w64-mingw32-ld
	PKGCONFIG = x86_64-w64-mingw32-pkg-config
	FLAGS = \
		--cc=$(CC) \
		--pkg-config=$(PKGCONFIG) \
		-D WINDOWS
	BINEXT = .exe
	LIBEXT = lib
else
	AR = ar
	PKGCONFIG = pkg-config
	LIBEXT = a
endif


ifeq ($(DEBUG), yes)
	FLAGS += \
		-g \
		--save-temps \
		-D DEBUG
else
	FLAGS += \
		--Xcc="-w"
endif

NAME = od
VAPI_DIR = $(BUILD_DIR)/vapi
INCLUDE_DIR = $(BUILD_DIR)/include
LIB_DIR = $(BUILD_DIR)/lib
_BUILD_DIR = $(BUILD_DIR)/$(NAME)
TARGET = $(LIB_DIR)/$(NAME).$(LIBEXT)

SOURCES = *.vala utils/*.vala ooxml/*.vala
PACKAGES = gio-2.0 gee-0.8 libxml-2.0


$(TARGET): *.vala $(VAPI_DIR)/archive.vapi
	rm -rf $(_BUILD_DIR)
	mkdir -p $(_BUILD_DIR)
	mkdir -p $(INCLUDE_DIR)
	mkdir -p $(VAPI_DIR)
	mkdir -p $(LIB_DIR)
	cd $(_BUILD_DIR) && \
		valac $(FLAGS) $(foreach pkg,$(PACKAGES),--pkg=$(pkg)) --library=$(NAME) --use-header --header=$(NAME).h --Xcc="-I$(INCLUDE_DIR)" --compile $(foreach src,$(SOURCES), $(CURDIR)/$(src)) && \
		$(AR) rcs $@ *.o
	mv $(_BUILD_DIR)/$(NAME).h $(INCLUDE_DIR)
	mv $(_BUILD_DIR)/$(NAME).vapi $(VAPI_DIR)
	rm -f $(_BUILD_DIR)/*.o


clean:
	rm -rf $(_BUILD_DIR)
	rm -f $(VAPI_DIR)/$(NAME).vapi
	rm -f $(INCLUDE_DIR)/$(NAME).h
	rm -f $(TARGET)
