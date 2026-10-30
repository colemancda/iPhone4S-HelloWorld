# iPhone4S-HelloWorld

iPhone 4S Hello World app built with Xcode 27.1 and Swift 6.4.

A minimal UIKit app for the jailbroken iPhone 4S (iPhone4,1, armv7, iOS 9.3.6),
built with the current Xcode's command-line tools instead of an old Xcode.
Part of it is written in Embedded Swift from the latest swift.org toolchain.
There's also a Swift command-line tool.

## How it works

- **Compiler and linker:** Xcode 27's `clang` and `ld` still support armv7.
- **SDK:** `sdk/iPhoneOS9.3.sdk` comes from [theos/sdks](https://github.com/theos/sdks)
  (release `master-146e41f`, file `iPhoneOS9.3.sdk.tar.xz`). It isn't checked in.
  Download the archive, then run `make sdk SDK_ARCHIVE=/path/to/iPhoneOS9.3.sdk.tar.xz`.
  That unpacks it and removes `i386, x86_64` from the `.tbd` stubs. Without that,
  Xcode 27's linker reads the stubs as simulator libraries and the link fails.
  It also adds `memcpy`, `memmove`, `memset`, `bzero` and `memcmp`, which the
  stubs leave out but Swift's standard library calls directly.
- **Swift:** see [Swift](#swift) below.
- **Signing:** `ldid -S` (Homebrew) adds the ad-hoc signature a jailbroken
  device accepts.
- **Install:** the app goes into `/Applications` on the phone over SSH, and
  `uicache` adds it to the home screen. Apps there run without AppSync.

## Commands

```bash
make          # build build/HelloWorld.app
make install  # copy to the 4S over USB SSH and refresh the home screen
make ipa      # package build/HelloWorld.ipa
make cli      # build the Swift command-line tool, build/hello-swift
make run-cli  # copy it to the 4S and run it there
make sdk      # re-create sdk/ from the preserved archive
make clean
```

`make install` needs a jailbroken phone with OpenSSH, and the USB tunnel to it
running (from libimobiledevice; add `-u <UDID>` if more than one device is plugged in):

```bash
iproxy 2222:22
```

It connects with the SSH config file in `SSH_CONF` (key login as root). The
phone's SSH server only offers old key types, so the config needs a host entry
named `4s` like this:

```
Host 4s
  HostName 127.0.0.1
  Port 2222
  User root
  IdentityFile ~/.ssh/iphone4s_ed25519
  IdentitiesOnly yes
  HostKeyAlgorithms +ssh-rsa
  PubkeyAcceptedAlgorithms +ssh-rsa
  KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group1-sha1
```

```bash
make install SSH_CONF=/path/to/that/config
```

## Swift

`swift/Hello4S.swift` is [Embedded Swift](https://www.swift.org/getting-started/embedded-swift/),
the subset of Swift that compiles without a runtime library. The app calls its
`@c` functions from Objective-C through `swift/Hello4S.h`. `cli/main.swift` is a
command-line tool built from the same Swift code.

```
$ make run-cli
Hello from Swift 6.4, iPhone 4S!
1² + 2² + 3² + 4² + 5² = 55
```

**Toolchain:** Xcode's Swift has no Embedded standard library. Install the
swift.org toolchain (6.4.2) from <https://www.swift.org/install/macos/>, or set
`SWIFT_TOOLCHAIN` to another `.xctoolchain`. It's used only for the Swift files;
clang, the linker and the SDK still come from Xcode.

**How it builds:** there is no `armv7-apple-ios` Embedded stdlib, so Swift
targets `armv7-apple-none-macho` (bare-metal armv7 Mach-O), and the object is
linked into the iOS binary. The linker warns "no platform load command found"
for it and assumes iOS, which is correct. Two flags fix the differences between
the bare-metal and iOS conventions:

- `-Xcc -marm` builds ARM code instead of Thumb, for the same linker bug as below.
- `-Xcc -ffixed-r9` keeps Swift from using `r9`. iOS lets any function overwrite
  `r9`, but the bare-metal target expects it to survive calls. Without this flag,
  Swift crashes after its first call into libSystem.

**What Embedded Swift can't do:** use Foundation, define `@objc` classes or use
Objective-C interop, use reflection (`Mirror`), use `Codable`, or use most
`any` existentials. `print` takes a single string. Passing floats or structs
to iOS C functions is untested and may hit further calling-convention
differences.

## Limits

- Code is built in ARM mode (`-marm`), not Thumb. Xcode 27's linker writes an
  even `LC_MAIN` entry offset for a Thumb `main()`, so dyld starts it in ARM
  state and the app crashes at launch (`EXC_BAD_ACCESS` at the first call in `main`).
- UIKit is driven from Objective-C. Swift supplies logic through `@c` functions
  (see [Swift](#swift)).
- OpenGL ES 2.0 only (A5 GPU). No Metal.
- APIs newer than iOS 9.3 don't exist on the device even if they compile.
- The Xcode IDE can't target iOS 9. Edit in Xcode if you like, but build with `make`.
