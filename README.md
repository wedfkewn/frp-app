# LocalBridge iOS MVP

Native SwiftUI client for IKEv2 system VPN and a foreground-only 127.0.0.1 TCP forwarding proxy.

Features: endpoint management, NEVPNManager with Keychain-backed credentials, local TCP relay through Network.framework, WKWebView, Safari launch, and GitHub Actions simulator build.

Requirements: iOS 17+, Xcode 16+, XcodeGen, Personal VPN capability and a working IKEv2 gateway with a trusted certificate.

Build: install XcodeGen and run xcodegen generate, then open LocalBridge.xcodeproj. CI builds an unsigned iOS Simulator .app artifact; this is not an installable, signed iPhone IPA.

Limitations: the 127.0.0.1 proxy only operates reliably while the app remains foregrounded. Safari can instead reach a remote private IP through the system VPN once the VPN is connected and routing configured. No WireGuard, NAT hole punching or gateway installer is included.

Security: do not commit passwords or private keys. Restrict all services to authorized hosts and retain application authentication. The local listener binds only to 127.0.0.1.

License: MIT.
