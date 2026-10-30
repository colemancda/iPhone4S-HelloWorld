# iPhone4S-HelloWorld

iPhone 4S Hello World app built with Xcode 27.1.

A minimal UIKit app for the jailbroken iPhone 4S (iPhone4,1, armv7, iOS 9.3.6),
built with the current Xcode's command-line tools instead of an old Xcode.

## How it works

- **Compiler and linker:** Xcode 27's `clang` and `ld` still support armv7.
- **SDK:** `sdk/iPhoneOS9.3.sdk` comes from [theos/sdks](https://github.com/theos/sdks)
  (release `master-146e41f`, file `iPhoneOS9.3.sdk.tar.xz`). It isn't checked in.
  Download the archive, then run `make sdk SDK_ARCHIVE=/path/to/iPhoneOS9.3.sdk.tar.xz`.
  That unpacks it and removes `i386, x86_64` from the `.tbd` stubs. Without that,
  Xcode 27's linker reads the stubs as simulator libraries and the link fails.
- **Signing:** `ldid -S` (Homebrew) adds the ad-hoc signature a jailbroken
  device accepts.
- **Install:** the app goes into `/Applications` on the phone over SSH, and
  `uicache` adds it to the home screen. Apps there run without AppSync.

## Commands

```bash
make          # build build/HelloWorld.app
make install  # copy to the 4S over USB SSH and refresh the home screen
make ipa      # package build/HelloWorld.ipa
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

## Limits

- Code is built in ARM mode (`-marm`), not Thumb. Xcode 27's linker writes an
  even `LC_MAIN` entry offset for a Thumb `main()`, so dyld starts it in ARM
  state and the app crashes at launch (`EXC_BAD_ACCESS` at the first call in `main`).
- Objective-C only. Swift would need an old Swift runtime for armv7/iOS 9.
- OpenGL ES 2.0 only (A5 GPU). No Metal.
- APIs newer than iOS 9.3 don't exist on the device even if they compile.
- The Xcode IDE can't target iOS 9. Edit in Xcode if you like, but build with `make`.
