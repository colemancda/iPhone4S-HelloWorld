# Builds an armv7 / iOS 9 app for the iPhone 4S with the current Xcode's clang
# and the iOS 9.3 SDK in ./sdk (from github.com/theos/sdks).

APP      := HelloWorld
BUNDLE   := build/$(APP).app
SDK      := sdk/iPhoneOS9.3.sdk
MIN_IOS  := 9.0
ARCH     := armv7

CC       := xcrun clang
# -marm: Xcode 27's linker writes an even LC_MAIN entry offset for Thumb code,
# so dyld enters a Thumb main() in ARM state and the app crashes at launch.
CFLAGS   := -arch $(ARCH) -isysroot $(SDK) -miphoneos-version-min=$(MIN_IOS) \
            -marm -fobjc-arc -O2 -Wall
LDFLAGS  := -arch $(ARCH) -isysroot $(SDK) -miphoneos-version-min=$(MIN_IOS) \
            -framework UIKit -framework Foundation

# Install target on the jailbroken 4S (SSH over USB via iproxy, see README)
SSH_CONF ?= /Volumes/4TB/Downloads/IPA/4s-ssh.conf
SSH_HOST ?= 4s

SRCS := $(wildcard src/*.m)
OBJS := $(patsubst src/%.m,build/obj/%.o,$(SRCS))

# Preserved, unmodified copy of the SDK (sha256 in the .sha256 file next to it)
SDK_ARCHIVE ?= /Volumes/4TB/Downloads/iPhoneOS9.3.sdk.tar.xz

.PHONY: all clean ipa install sdk
.DEFAULT_GOAL := all

# Unpacks the SDK and drops i386/x86_64 from its .tbd stubs: Xcode 27's linker
# reads the mixed device/simulator stubs as simulator-only and refuses to link.
sdk:
	rm -rf $(SDK) && mkdir -p sdk
	tar -xJf $(SDK_ARCHIVE) -C sdk
	find $(SDK) -name '*.tbd' -type f -print0 | xargs -0 sed -i '' -E \
	  's/(archs: *\[ armv7, armv7s, arm64), i386, x86_64 \]/\1 ]/'

all: $(BUNDLE)/$(APP)

build/obj/%.o: src/%.m
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUNDLE)/$(APP): $(OBJS) src/Info.plist
	@mkdir -p $(BUNDLE)
	$(CC) $(LDFLAGS) $(OBJS) -o $@.tmp
	ldid -S $@.tmp
	mv $@.tmp $@
	plutil -convert binary1 -o $(BUNDLE)/Info.plist src/Info.plist
	printf 'APPL????' > $(BUNDLE)/PkgInfo

ipa: $(BUNDLE)/$(APP)
	rm -rf build/ipa && mkdir -p build/ipa/Payload
	cp -R $(BUNDLE) build/ipa/Payload/
	cd build/ipa && COPYFILE_DISABLE=1 zip -qr ../$(APP).ipa Payload

# Copies the app into /Applications and refreshes the home screen.
# Apps in /Applications run on a jailbroken device without AppSync.
install: $(BUNDLE)/$(APP)
	COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata -C build -cf - $(APP).app | \
	  ssh -F $(SSH_CONF) $(SSH_HOST) 'cd / && rm -rf /Applications/$(APP).app && tar -C /Applications -xf - && chown -R root:wheel /Applications/$(APP).app && su mobile -c uicache'

clean:
	rm -rf build
