import SwiftUI
import WebKit

struct ServiceDetailView: View {
    let service: ServiceEndpoint
    @EnvironmentObject private var proxy: LoopbackProxy
    @State private var showingWebView = false
    @Environment(\.openURL) private var openURL

    private var active: Bool { proxy.activeServiceID == service.id }

    var body: some View {
        List {
            Section("Safari · VPN 模式") {
                LabeledContent("地址", value: service.remoteURL?.absoluteString ?? "无效")
                Button("在 Safari 打开虚拟 IP") {
                    if let url = service.remoteURL { openURL(url) }
                }
                Text("VPN 连接后，Safari 可以通过内网虚拟 IP 访问，主 App 不必持续在前台。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("127.0.0.1 · 前台模式") {
                LabeledContent("本地地址", value: service.loopbackURL?.absoluteString ?? "无效")
                Button(active ? "停止本地代理" : "启动本地代理") {
                    if active { proxy.stop() } else { proxy.start(service) }
                }
                Button("在 App 内打开本地网页") { showingWebView = true }
                    .disabled(!active)
                Text("离开 App 后 iOS 可能挂起本地 TCP 监听器；不可把此模式当作后台服务。")
                    .font(.footnote).foregroundStyle(.orange)
            }
        }
        .navigationTitle(service.name)
        .sheet(isPresented: $showingWebView) {
            if let url = service.loopbackURL {
                NavigationStack {
                    BrowserView(url: url)
                        .navigationTitle(service.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("关闭") { showingWebView = false }
                            }
                        }
                }
            }
        }
        .alert("本地代理错误", isPresented: Binding(
            get: { proxy.errorMessage != nil },
            set: { if !$0 { proxy.errorMessage = nil } }
        )) {
            Button("好的", role: .cancel) { proxy.errorMessage = nil }
        } message: { Text(proxy.errorMessage ?? "") }
    }
}

private struct BrowserView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
