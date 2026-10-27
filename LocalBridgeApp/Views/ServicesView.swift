import SwiftUI

struct ServicesView: View {
    @EnvironmentObject private var store: ServiceStore
    @EnvironmentObject private var vpn: VPNController
    @EnvironmentObject private var proxy: LoopbackProxy
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: vpn.connected ? "checkmark.shield.fill" : "shield.slash")
                            .foregroundStyle(vpn.connected ? .green : .secondary)
                        Text("VPN：\(vpn.statusText)")
                        Spacer()
                        Text("IKEv2").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("远程服务") {
                    if store.services.isEmpty {
                        ContentUnavailableView(
                            "暂无服务",
                            systemImage: "server.rack",
                            description: Text("添加一个你已授权访问的远端网页。")
                        )
                    } else {
                        ForEach(store.services) { service in
                            NavigationLink(value: service) {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(service.name).font(.headline)
                                        Text("\(service.host):\(service.port)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "network")
                                }
                            }
                        }
                        .onDelete { offsets in
                            if let active = proxy.activeServiceID,
                               offsets.contains(where: { store.services[$0].id == active }) {
                                proxy.stop()
                            }
                            store.delete(at: offsets)
                        }
                    }
                }
                Section {
                    Text("Safari 后台访问需使用 VPN 内网地址。本地 127.0.0.1 模式仅在 App 前台运行时可靠。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("LocalBridge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddServiceView() }
            .navigationDestination(for: ServiceEndpoint.self) { service in
                ServiceDetailView(service: service)
            }
        }
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

    var body: some View {
        NavigationStack {
            Form {
                Section("远端网页") {
                    TextField("名称", text: $name)
                    TextField("目标 IP / 域名", text: $host)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("服务端口", text: $port).keyboardType(.numberPad)
                }
                Section("前台本地代理") {
                    TextField("127.0.0.1 端口", text: $localPort).keyboardType(.numberPad)
                }
            }
            .navigationTitle("添加服务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        do {
                            let entry = ServiceEndpoint(
                                name: name, host: host,
                                port: Int(port) ?? 0,
                                localPort: Int(localPort) ?? 0
                            )
                            try store.add(entry)
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
            .alert("配置错误", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("好的", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
    }
}
