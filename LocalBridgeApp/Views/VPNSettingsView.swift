import SwiftUI

struct VPNSettingsView: View {
    @EnvironmentObject private var vpn: VPNController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var password = ""
    @State private var busy = false

    private var loading: Bool { busy || vpn.connecting }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusCard

                    Text("IKEv2 服务器")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 18) {
                            field("服务器地址", systemImage: "server.rack") {
                                TextField("vpn.example.com", text: $vpn.profile.server)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .textContentType(.URL)
                            }
                            Divider()
                            field("证书标识", systemImage: "checkmark.shield") {
                                TextField("vpn.example.com", text: $vpn.profile.remoteIdentifier)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            Divider()
                            field("EAP 用户名", systemImage: "person") {
                                TextField("用户名", text: $vpn.profile.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.username)
                            }
                            Divider()
                            field("EAP 密码", systemImage: "lock") {
                                SecureField("已保存可留空", text: $password)
                                    .textContentType(.password)
                            }
                        }
                    }

                    Label("首次连接时，iOS 会请求添加 VPN 配置。请确保网关使用有效且受信任的证书。",
                          systemImage: "lock.shield")
                        .font(.footnote)
                        .foregroundStyle(BridgeStyle.secondary)
                        .padding(.horizontal, 6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await vpn.reloadStatus() }
            .navigationTitle("连接管理")
            .bridgePageBackground()
            .animation(reduceMotion ? nil : BridgeStyle.spring, value: vpn.status)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 10) {
                    Button {
                        guard !busy else { return }
                        busy = true
                        Task {
                            await vpn.configureAndConnect(password: password)
                            password = ""
                            busy = false
                        }
                    } label: {
                        BridgeButtonLabel(
                            title: busy ? "正在保存 VPN" : (vpn.connecting ? "正在连接 VPN" : "保存并连接"),
                            symbol: "bolt.horizontal.fill",
                            spinning: loading
                        )
                    }
                    .bridgePrimaryButton()
                    .disabled(loading || vpn.connected)

                    if vpn.connected {
                        Button(role: .destructive) {
                            vpn.disconnect()
                        } label: {
                            Label("断开 VPN 连接", systemImage: "power")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.regularMaterial)
            }
            .alert("VPN 连接错误", isPresented: Binding(
                get: { vpn.errorMessage != nil },
                set: { if !$0 { vpn.errorMessage = nil } }
            )) {
                Button("知道了", role: .cancel) { vpn.errorMessage = nil }
            } message: { Text(vpn.errorMessage ?? "") }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 15) {
            ConnectionOrb(connected: vpn.connected, loading: loading)
            VStack(alignment: .leading, spacing: 9) {
                Text("连接状态")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                Text(vpn.statusText)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(vpn.connected ? "隧道正在运行" : (loading ? "正在安全建立隧道…" : "输入网关信息开始连接"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.41, blue: 0.81), Color(red: 0.07, green: 0.20, blue: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private func field<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BridgeStyle.secondary)
            content()
                .font(.body)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 13)
                .padding(.vertical, 14)
                .background(BridgeStyle.background, in: RoundedRectangle(cornerRadius: 13))
        }
    }
}
