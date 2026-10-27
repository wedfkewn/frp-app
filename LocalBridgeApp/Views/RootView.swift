import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ServicesView()
                .tabItem { Label("服务", systemImage: "server.rack") }
            VPNSettingsView()
                .tabItem { Label("VPN", systemImage: "network.badge.shield.half.filled") }
            AboutView()
                .tabItem { Label("说明", systemImage: "info.circle") }
        }
        .tint(.blue)
    }
}

private struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("工作方式") {
                    Text("系统 IKEv2 VPN 可在主 App 切换后台后继续工作。连接后直接在 Safari 打开远端 VPN IP。")
                    Text("127.0.0.1 转发只在本 App 前台运行时可靠；切换 Safari 后可能被系统挂起。")
                }
                Section("安全与隐私") {
                    Text("设备配置保存在本机，VPN 密码存放在钥匙串。")
                    Text("请仅连接获授权的服务器，验证 IKEv2 服务器证书。")
                }
                Section("版本") {
                    LabeledContent("版本", value: "MVP · IKEv2 + 前台 TCP 转发")
                    LabeledContent("最低 iOS", value: "17")
                }
            }
            .navigationTitle("关于 LocalBridge")
        }
    }
}
