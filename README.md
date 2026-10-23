# Cryptomator macOS Integrations

macOS-specific implementations of [integrations-api](https://github.com/cryptomator/integrations-api).

## Usage

### Touch ID keychain

`TouchIdKeychainAccess` stores passwords in the data protection keychain, protected by Touch ID with the device password as fallback. The provider is only supported if the app is signed with an entitlement granting a keychain access group (e.g. `keychain-access-groups`).

## Building

Since this project involves JNI, you need Java as well as Xcode build tools:

* JDK 25
* XCode Command Line Tools (run `xcode-select --install`)
