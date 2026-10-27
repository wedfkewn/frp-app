import SwiftUI

/// Adaptive, Dynamic Type-friendly components. No fixed screen sizes or notch offsets.
enum BridgeStyle {
    static let tint = Color(red: 0.12, green: 0.46, blue: 0.93)
    static let teal = Color(red: 0.08, green: 0.72, blue: 0.68)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let secondary = Color(uiColor: .secondaryLabel)
    static let hairline = Color(uiColor: .separator).opacity(0.20)
    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.84)
}

struct BridgeCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BridgeStyle.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(BridgeStyle.hairline, lineWidth: 0.8)
            }
    }
}

struct BridgePill: View {
    var text: String
    var color: Color
    var symbol: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(color.opacity(0.10), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct BridgeButtonLabel: View {
    let title: String
    let symbol: String
    var spinning = false

    var body: some View {
        HStack(spacing: 10) {
            if spinning {
                ProgressView().tint(.white)
            } else {
                Image(systemName: symbol).font(.headline)
            }
            Text(title).font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct ConnectionOrb: View {
    var connected: Bool
    var loading: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    private var color: Color {
        connected ? BridgeStyle.teal : (loading ? .orange : .white.opacity(0.75))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.40), lineWidth: 1.5)
                .frame(width: 92, height: 92)
                .scaleEffect(expanded ? 1.18 : 0.88)
                .opacity(expanded ? 0.10 : 0.68)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: expanded
                )
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 78, height: 78)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
            if loading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            } else {
                Image(systemName: connected ? "checkmark.shield.fill" : "network")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .frame(width: 104, height: 108)
        .onAppear { expanded = true }
        .accessibilityLabel(loading ? "正在连接" : (connected ? "已连接" : "未连接"))
    }
}

extension View {
    func bridgePageBackground() -> some View {
        self.background(BridgeStyle.background.ignoresSafeArea())
    }

    func bridgePrimaryButton() -> some View {
        self.buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [BridgeStyle.tint, BridgeStyle.tint.opacity(0.84)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
    }
}
