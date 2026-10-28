import SwiftUI

private enum LocalTab: Hashable {
    case quick, ssh, devices, info
}

struct RootView: View {
    @State private var tab: LocalTab = .quick

    var body: some View {
        TabView(selection: $tab) {
            SSHQuickHomeView(configure: { withAnimation(BridgeStyle.spring) { tab = .ssh } })
                .tabItem { Label("快捷", systemImage: "square.grid.2x2.fill") }
                .tag(LocalTab.quick)

            SSHSettingsView()
                .tabItem { Label("SSH", systemImage: "network") }
                .tag(LocalTab.ssh)

            ServicesView(onOpenVPN: { withAnimation(BridgeStyle.spring) { tab = .ssh } })
                .tabItem { Label("服务", systemImage: "server.rack") }
                .tag(LocalTab.devices)

            AboutView()
                .tabItem { Label("关于", systemImage: "info.circle") }
                .tag(LocalTab.info)
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
                            Text("安全连接远程服务，快捷打开四个常用网页")
                                .foregroundStyle(BridgeStyle.secondary)
                            BridgePill(text: "iOS 17+ · 自适应布局", color: BridgeStyle.tint, symbol: "iphone")
                        }
                    }
                    BridgeCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("SSH 本地转发", systemImage: "terminal")
                                .font(.headline)
                            Text("根据 BAT 文件，iPhone 使用 SSH 连接远端服务器并建立四个本机端口。")
                            Text("SSH 转发依赖前台运行。切换到 Safari 或锁屏后连接可能被系统暂停，因此优先使用 App 内浏览器。")
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                    }
                    BridgeCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("安全说明", systemImage: "lock.shield")
                                .font(.headline)
                            Text("密码仅存储在手机钥匙串，SSH 主机公钥必须事先核实。请勿将 SSH 私钥上传到 GitHub。")
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("关于")
            .bridgePageBackground()
        }
    }
}
