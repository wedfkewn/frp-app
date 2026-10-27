import SwiftUI

private enum LocalTab: Hashable {
    case devices
    case vpn
    case about
}

struct RootView: View {
    @State private var tab: LocalTab = .devices

    var body: some View {
        TabView(selection: $tab) {
            ServicesView(onOpenVPN: { withAnimation(BridgeStyle.spring) { tab = .vpn } })
                .tabItem { Label("服务", systemImage: "square.stack.3d.up") }
                .tag(LocalTab.devices)

            VPNSettingsView()
                .tabItem { Label("连接", systemImage: "shield.lefthalf.filled") }
                .tag(LocalTab.vpn)

            AboutView()
                .tabItem { Label("关于", systemImage: "info.circle") }
                .tag(LocalTab.about)
        }
        .tint(BridgeStyle.tint)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

private struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BridgeCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 30))
                                .foregroundStyle(BridgeStyle.tint)
                            Text("LocalBridge")
                                .font(.title2.bold())
                            Text("安全连接你的远程服务")
                                .foregroundStyle(BridgeStyle.secondary)
                            BridgePill(text: "iOS 17+ · 自适应布局", color: BridgeStyle.tint, symbol: "iphone")
                        }
                    }

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("两种连接方式", systemImage: "arrow.triangle.branch")
                                .font(.headline)
                            Text("VPN 模式：连接已有 IKEv2 网关后，通过 Safari 使用远端虚拟 IP。")
                            Divider()
                            Text("回环模式：App 前台监听 127.0.0.1，使用内置浏览器访问服务。切到后台后不保证保持监听。")
                        }
                    }

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("安全说明", systemImage: "lock.shield")
                                .font(.headline)
                            Text("VPN 密码保存在设备钥匙串。仅连接自己管理或经授权的服务器，并确认网关证书有效。")
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("关于")
            .bridgePageBackground()
        }
    }
}
