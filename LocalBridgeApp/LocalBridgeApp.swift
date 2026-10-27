import SwiftUI

@main
struct LocalBridgeApp: App {
    @StateObject private var services = ServiceStore()
    @StateObject private var vpn = VPNController()
    @StateObject private var proxy = LoopbackProxy()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
                .environmentObject(vpn)
                .environmentObject(proxy)
                .task { await vpn.reloadStatus() }
        }
    }
}
