import SwiftUI

struct SSHSettingsView: View {
    @EnvironmentObject private var tunnel: SSHTunnelManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var password = ""
    @State private var portText = "22"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ConnectionOrb(connected: tunnel.connected, loading: tunnel.connecting)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(tunnel.statusText).font(.title3.bold())
                            Text("SSH · 本地四端口转发")
                                .font(.subheadline)
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 18) {
                            input("服务器 IP / 域名", symbol: "server.rack") {
                                TextField("例如 203.0.113.10", text: $tunnel.profile.host)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                            }
                            Divider()
                            input("SSH 用户名", symbol: "person") {
                                TextField("ubuntu", text: $tunnel.profile.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            Divider()
                            input("SSH 端口", symbol: "network") {
                                TextField("22", text: $portText)
                                    .keyboardType(.numberPad)
                                    .onChange(of: portText) { _, newValue in
                                        tunnel.profile.port = Int(newValue) ?? 0
                                    }
                            }
                            Divider()
                            input("SSH 登录密码", symbol: "lock") {
                                SecureField("密码（已保存可留空）", text: $password)
                                    .textContentType(.password)
                            }
                        }
                    }

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("服务器主机公钥（首次连接必填）", systemImage: "checkmark.shield")
                                .font(.subheadline.weight(.semibold))
                            TextEditor(text: $tunnel.profile.trustedHostKey)
                                .frame(minHeight: 88, maxHeight: 110)
                                .font(.footnote.monospaced())
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(BridgeStyle.background,
                                            in: RoundedRectangle(cornerRadius: 12))
                            Text("可在自己服务器的 SSH 终端执行 cat /etc/ssh/ssh_host_ed25519_key.pub，复制整行并通过可信渠道核对。不要粘贴 PRIVATE KEY。")
                                .font(.footnote)
                                .foregroundStyle(BridgeStyle.secondary)
                            Text("你的 BAT 使用的是私钥登录。如果服务器关闭 PasswordAuthentication，必须另行实现私钥导入，密码无法代替密钥。")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("转发端口", systemImage: "point.3.connected.trianglepath.dotted")
                                .font(.subheadline.weight(.semibold))
                            Text("6081 · 5099 · 3080 · 18787")
                                .font(.subheadline.monospaced())
                            Text("每个本地端口对应服务器 127.0.0.1 上的同端口服务。")
                                .font(.footnote)
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 26)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .bridgePageBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("SSH 连接")
            .animation(reduceMotion ? nil : BridgeStyle.spring, value: tunnel.phase)
            .onAppear { portText = String(tunnel.profile.port) }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    if tunnel.connected {
                        Button(role: .destructive) { tunnel.disconnect() } label: {
                            BridgeButtonLabel(title: "断开 SSH 隧道", symbol: "stop.circle.fill")
                        }
                        .bridgePrimaryButton()
                    } else {
                        Button {
                            Task {
                                await tunnel.connect(password: password)
                                password = ""
                            }
                        } label: {
                            BridgeButtonLabel(
                                title: tunnel.connecting ? "连接中…" : "建立 SSH 隧道",
                                symbol: "link",
                                spinning: tunnel.connecting
                            )
                        }
                        .bridgePrimaryButton()
                        .disabled(tunnel.connecting)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
            .alert("SSH 连接失败", isPresented: Binding(
                get: { tunnel.errorMessage != nil },
                set: { if !$0 { tunnel.errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) { tunnel.errorMessage = nil }
            } message: {
                Text(tunnel.errorMessage ?? "")
            }
        }
    }

    private func input<Content: View>(_ title: String, symbol: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BridgeStyle.secondary)
            content()
                .font(.body)
                .padding(12)
                .background(BridgeStyle.background,
                            in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
