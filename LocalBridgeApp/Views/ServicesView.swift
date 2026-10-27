import SwiftUI

struct ServicesView: View {
    var onOpenVPN: () -> Void

    @EnvironmentObject private var store: ServiceStore
    @EnvironmentObject private var vpn: VPNController
    @EnvironmentObject private var proxy: LoopbackProxy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("远程服务")
                                .font(.title3.bold())
                            Text("\(store.services.count) 个已保存的服务")
                                .font(.subheadline)
                                .foregroundStyle(BridgeStyle.secondary)
                        }
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Label("添加", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(BridgeStyle.tint.opacity(0.10), in: Capsule())
                        }
                        .accessibilityLabel("添加远程服务")
                    }

                    if store.services.isEmpty {
                        emptyState
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.services) { service in
                                NavigationLink(value: service) {
                                    serviceRow(service)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if let url = service.remoteURL {
                                        ShareLink(item: url) {
                                            Label("分享访问地址", systemImage: "square.and.arrow.up")
                                        }
                                    }
                                    Button(role: .destructive) { delete(service) } label: {
                                        Label("删除服务", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Label("Safari 后台访问使用 VPN 虚拟 IP；127.0.0.1 转发仅在 App 前台可靠。",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(BridgeStyle.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("LocalBridge")
            .navigationBarTitleDisplayMode(.large)
            .bridgePageBackground()
            .refreshable { await vpn.reloadStatus() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("新增服务")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddServiceView()
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: ServiceEndpoint.self) { service in
                ServiceDetailView(service: service)
            }
            .animation(reduceMotion ? nil : BridgeStyle.spring, value: store.services.count)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 15) {
                ConnectionOrb(connected: vpn.connected, loading: vpn.connecting)
                VStack(alignment: .leading, spacing: 5) {
                    Text(vpn.connected ? "连接已建立" : (vpn.connecting ? "正在建立连接" : "随时连接远程设备"))
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(vpn.connected ? "现在可以访问 VPN 内网服务" : "配置 VPN，安全访问你的远程网页")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack {
                Label(vpn.statusText, systemImage: vpn.connected ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onOpenVPN) {
                    HStack(spacing: 4) {
                        Text("VPN 设置")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [
                Color(red: 0.13, green: 0.40, blue: 0.82),
                Color(red: 0.08, green: 0.18, blue: 0.43)
            ], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var emptyState: some View {
        BridgeCard {
            VStack(spacing: 14) {
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 38))
                    .foregroundStyle(BridgeStyle.tint)
                    .padding(14)
                    .background(BridgeStyle.tint.opacity(0.08), in: Circle())
                Text("还没有添加服务")
                    .font(.headline)
                Text("保存常用的 NAS、控制台或开发网页，从这里快速访问。")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(BridgeStyle.secondary)
                Button {
                    showingAdd = true
                } label: {
                    BridgeButtonLabel(title: "添加第一个服务", symbol: "plus")
                }
                .bridgePrimaryButton()
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func serviceRow(_ service: ServiceEndpoint) -> some View {
        BridgeCard {
            HStack(spacing: 13) {
                Image(systemName: "server.rack")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(BridgeStyle.tint)
                    .frame(width: 48, height: 48)
                    .background(BridgeStyle.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text(service.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(service.host):\(service.port)")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(BridgeStyle.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if proxy.activeServiceID == service.id {
                        BridgePill(
                            text: proxy.phase == .ready ? "本地转发中" : "代理启动中",
                            color: proxy.phase == .ready ? BridgeStyle.teal : .orange,
                            symbol: proxy.phase == .ready ? "checkmark.circle" : "clock"
                        )
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(BridgeStyle.secondary)
            }
        }
    }

    private func delete(_ service: ServiceEndpoint) {
        if proxy.activeServiceID == service.id { proxy.stop() }
        store.services.removeAll { $0.id == service.id }
    }
}

private struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ServiceStore
    @State private var name = ""
    @State private var host = "10.77.0.2"
    @State private var port = "3000"
    @State private var localPort = "8080"
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例如：家庭 NAS", text: $name)
                        .textContentType(.nickname)
                    TextField("IP 地址 / 域名", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("目标端口", text: $port)
                        .keyboardType(.numberPad)
                } header: {
                    Label("远端网页服务", systemImage: "server.rack")
                } footer: {
                    Text("远端设备必须在已连接的 VPN 内可达。")
                }
                Section {
                    TextField("本地端口", text: $localPort)
                        .keyboardType(.numberPad)
                } header: {
                    Label("本地回环端口", systemImage: "point.3.connected.trianglepath.dotted")
                } footer: {
                    Text("将在 App 前台监听 127.0.0.1:\(localPort)。")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("添加远程服务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(action: save) {
                    BridgeButtonLabel(title: saving ? "保存中" : "保存服务", symbol: "checkmark", spinning: saving)
                }
                .bridgePrimaryButton()
                .disabled(saving)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
            .alert("无法保存", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("知道了", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    private func save() {
        guard !saving else { return }
        saving = true
        do {
            let entry = ServiceEndpoint(
                name: name, host: host,
                port: Int(port) ?? 0,
                localPort: Int(localPort) ?? 0
            )
            try store.add(entry)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
