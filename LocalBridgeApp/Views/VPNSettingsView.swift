import SwiftUI

struct VPNSettingsView: View {
    @EnvironmentObject private var vpn: VPNController
    @State private var password = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("当前状态") {
                    LabeledContent("连接", value: vpn.statusText)
                    if vpn.connected {
                        Button("断开 VPN", role: .destructive) { vpn.disconnect() }
                    }
                }
                Section("IKEv2 网关") {
                    TextField("公网域名或 IP", text: $vpn.profile.server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("服务器证书域名", text: $vpn.profile.remoteIdentifier)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("EAP 用户名", text: $vpn.profile.username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("EAP 密码（已保存可留空）", text: $password)
                        .textContentType(.password)
                }
                Section {
                    Button {
                        busy = true
                        Task {
                            await vpn.configureAndConnect(password: password)
                            password = ""
                            busy = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if busy { ProgressView() } else { Text("保存并连接 VPN") }
                            Spacer()
                        }
                    }
                    .disabled(busy)
                } footer: {
                    Text("需部署好 IKEv2 网关并配置可信服务器证书。首次安装 VPN 配置会触发系统授权，请在真机测试。")
                }
            }
            .navigationTitle("VPN 配置")
            .alert("VPN 错误", isPresented: Binding(
                get: { vpn.errorMessage != nil },
                set: { if !$0 { vpn.errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) { vpn.errorMessage = nil }
            } message: { Text(vpn.errorMessage ?? "") }
        }
    }
}
