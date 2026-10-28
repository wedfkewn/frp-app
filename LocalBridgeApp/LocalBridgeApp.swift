import SwiftUI

@main
struct LocalBridgeApp: App {
    @StateObject private var services = ServiceStore()
    @StateObject private var vpn = VPNController()
    @StateObject private var proxy = LoopbackProxy()
    @StateObject private var ssh = SSHTunnelManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
                .environmentObject(vpn)
                .environmentObject(proxy)
                .environmentObject(ssh)
                .task { await vpn.reloadStatus() }
        }
    }
}
