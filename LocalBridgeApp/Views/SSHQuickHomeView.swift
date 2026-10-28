import SwiftUI
import UIKit

/// Four links imported from the user's Windows ssh -L configuration.
/// The tunnel must be running locally on THIS iPhone; desktop 127.0.0.1 is unrelated.
struct SSHQuickHomeView: View {
    @EnvironmentObject private var tunnel: SSHTunnelManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    let configure: () -> Void
    @State private var selected: TunnelShortcut?
    @State private var pending: TunnelShortcut?
    @State private var showNotConnected = false

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusCard

                    HStack(alignment: .firstTextBaseline) {
                        Text("网页快捷入口")
                            .font(.title3.bold())
                        Spacer(minLength: 0)
                        Text("4 项")
                            .foregroundStyle(BridgeStyle.secondary)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 3)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TunnelShortcut.presets) { link in
                            Button {
                                if tunnel.connected {
                                    selected = link
                                } else {
                                    pending = link
                                    showNotConnected = true
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 13) {
                                    Image(systemName: link.symbol)
                                        .font(.system(size: 23, weight: .medium))
                                        .foregroundStyle(BridgeStyle.tint)
                                        .frame(width: 46, height: 46)
                                        .background(BridgeStyle.tint.opacity(0.11),
                                                    in: RoundedRectangle(cornerRadius: 14))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(link.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Text(link.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(BridgeStyle.secondary)
                                            .lineLimit(1)
                                        Text("127.0.0.1:\(link.port)")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(BridgeStyle.secondary)
                                            .minimumScaleFactor(0.76)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    HStack(spacing: 5) {
                                        Text("打开网页")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BridgeStyle.tint)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
                                .background(BridgeStyle.card,
                                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(BridgeStyle.hairline, lineWidth: 0.8)
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 22))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("打开\(link.title)，端口\(link.port)")
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = link.url.absoluteString
                                } label: {
                                    Label("复制本地地址", systemImage: "doc.on.doc")
                                }
                                Button {
                                    if tunnel.connected {
                                        openURL(link.url)
                                    } else {
                                        pending = link
                                        showNotConnected = true
                                    }
                                } label: {
                                    Label("在 Safari 打开", systemImage: "safari")
                                }
                            }
                        }
                    }

                    BridgeCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("来自电脑的 SSH 配置", systemImage: "terminal")
                                .font(.subheadline.weight(.semibold))
                            Text("四个端口和目标完全按 BAT 文件导入，远端目标均为服务器自身的 127.0.0.1。")
                                .font(.footnote)
                                .foregroundStyle(BridgeStyle.secondary)
                            Text("内置浏览器更适合前台 SSH 隧道；Safari 切换后台后，iOS 可能挂起 SSH 连接。")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 34)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .bridgePageBackground()
            .navigationTitle("快捷访问")
            .navigationBarTitleDisplayMode(.large)
            .animation(reduceMotion ? nil : BridgeStyle.spring, value: tunnel.phase)
            .sheet(item: $selected) { link in
                LocalBrowserScreen(url: link.url, title: link.title)
                    .presentationDragIndicator(.visible)
            }
            .alert("需要先建立 SSH 隧道", isPresented: $showNotConnected) {
                Button("前往连接设置") { configure() }
                Button("取消", role: .cancel) { pending = nil }
            } message: {
                Text("只有 iPhone 上的 SSH 隧道已连接，才能访问 \(pending?.url.absoluteString ?? "本地网页")。电脑上的 127.0.0.1 与手机互不相通。")
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ConnectionOrb(connected: tunnel.connected, loading: tunnel.connecting)
                VStack(alignment: .leading, spacing: 5) {
                    Text(tunnel.connected ? "SSH 隧道已连接" : (tunnel.connecting ? "正在建立 SSH 隧道" : "连接远程服务"))
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(tunnel.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Button(action: configure) {
                HStack {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                    Text(tunnel.connected ? "管理 SSH 连接" : "配置 IP 和密码并连接")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(13)
                .background(.white.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.42, blue: 0.86),
                         Color(red: 0.08, green: 0.17, blue: 0.42)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }
}
