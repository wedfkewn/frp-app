import SwiftUI
import WebKit
import UIKit

struct ServiceDetailView: View {
    let service: ServiceEndpoint

    @EnvironmentObject private var proxy: LoopbackProxy
    @EnvironmentObject private var vpn: VPNController
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingWebView = false
    @State private var copied = false

    private var active: Bool { proxy.activeServiceID == service.id }
    private var ready: Bool { active && proxy.phase == .ready }
    private var starting: Bool { active && proxy.phase == .starting }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BridgeCard {
                    HStack(spacing: 14) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 26))
                            .foregroundStyle(BridgeStyle.tint)
                            .frame(width: 60, height: 60)
                            .background(BridgeStyle.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(service.name)
                                .font(.title3.bold())
                            Text("\(service.host):\(service.port)")
                                .font(.subheadline.monospaced())
                                .foregroundStyle(BridgeStyle.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer(minLength: 0)
                    }
                }

                HStack {
                    Text("Safari 远程访问")
                        .font(.headline)
                    Spacer()
                    BridgePill(
                        text: vpn.connected ? "VPN 已连接" : "请先连接 VPN",
                        color: vpn.connected ? BridgeStyle.teal : .orange,
                        symbol: vpn.connected ? "checkmark.shield" : "exclamationmark.shield"
                    )
                }
                BridgeCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("远程地址", systemImage: "globe")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BridgeStyle.secondary)
                        Text(service.remoteURL?.absoluteString ?? "无效地址")
                            .font(.subheadline.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            if let url = service.remoteURL { openURL(url) }
                        } label: {
                            BridgeButtonLabel(title: "在 Safari 中打开", symbol: "safari.fill")
                        }
                        .bridgePrimaryButton()
                        Button {
                            if let text = service.remoteURL?.absoluteString {
                                UIPasteboard.general.string = text
                                withAnimation(reduceMotion ? nil : BridgeStyle.spring) { copied = true }
                            }
                        } label: {
                            Label(copied ? "已复制地址" : "复制链接", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(BridgeStyle.tint)
                        Text("VPN 已连接且配置正确路由后，即可通过 Safari 打开此地址。")
                            .font(.footnote)
                            .foregroundStyle(BridgeStyle.secondary)
                    }
                }

                Text("本地回环代理")
                    .font(.headline)

                BridgeCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("127.0.0.1 访问")
                                    .font(.subheadline.weight(.semibold))
                                Text(service.loopbackURL?.absoluteString ?? "无效地址")
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(BridgeStyle.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            BridgePill(
                                text: ready ? "正在监听" : (starting ? "启动中" : "未启动"),
                                color: ready ? BridgeStyle.teal : (starting ? .orange : BridgeStyle.secondary),
                                symbol: ready ? "checkmark.circle.fill" : (starting ? "clock" : "circle")
                            )
                        }

                        Button {
                            if active { proxy.stop() } else { proxy.start(service) }
                        } label: {
                            BridgeButtonLabel(
                                title: starting ? "正在启动代理" : (active ? "停止本地代理" : "启动本地代理"),
                                symbol: active ? "stop.fill" : "play.fill",
                                spinning: starting
                            )
                        }
                        .bridgePrimaryButton()
                        .disabled(starting)

                        Button { showingWebView = true } label: {
                            Label("在 App 内浏览网页", systemImage: "rectangle.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(BridgeStyle.tint.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!ready)
                        .foregroundStyle(ready ? BridgeStyle.tint : BridgeStyle.secondary)

                        Label("iOS 进入后台后可能暂停本地代理；请保持 App 在前台使用此功能。",
                              systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Button(role: .destructive) {
                    proxy.stop()
                    dismiss()
                } label: {
                    Label("停止转发并返回", systemImage: "xmark.circle")
                }
                .disabled(!active)
                .font(.footnote)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 30)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("服务详情")
        .navigationBarTitleDisplayMode(.inline)
        .bridgePageBackground()
        .animation(reduceMotion ? nil : BridgeStyle.spring, value: proxy.phase)
        .sheet(isPresented: $showingWebView) {
            if let url = service.loopbackURL {
                LocalBrowserScreen(url: url, title: service.name)
            }
        }
        .alert("本地代理错误", isPresented: Binding(
            get: { proxy.errorMessage != nil },
            set: { if !$0 { proxy.errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { proxy.errorMessage = nil }
        } message: { Text(proxy.errorMessage ?? "") }
    }
}

struct LocalBrowserScreen: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var loading = true
    @State private var progress = 0.1
    @State private var browserError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BrowserWebView(url: url, loading: $loading, progress: $progress, error: $browserError)
                    .ignoresSafeArea(edges: .bottom)

                if loading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)
                        Text("正在加载网页")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BridgeStyle.secondary)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if loading {
                    ProgressView(value: progress)
                        .tint(BridgeStyle.tint)
                        .transition(.opacity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("网页加载失败", isPresented: Binding(
                get: { browserError != nil },
                set: { if !$0 { browserError = nil } }
            )) {
                Button("确定", role: .cancel) { browserError = nil }
            } message: { Text(browserError ?? "") }
        }
    }
}

private struct BrowserWebView: UIViewRepresentable {
    let url: URL
    @Binding var loading: Bool
    @Binding var progress: Double
    @Binding var error: String?

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: BrowserWebView

        init(parent: BrowserWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.loading = true
                self.parent.progress = 0.2
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.progress = 0.7 }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.progress = 1.0
                withAnimation(.easeOut(duration: 0.2)) { self.parent.loading = false }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            failure(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            failure(error)
        }

        private func failure(_ error: Error) {
            DispatchQueue.main.async {
                self.parent.loading = false
                self.parent.error = error.localizedDescription
            }
        }
    }
}
