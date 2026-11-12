import Cocoa
import SwiftUI

struct CardContainerView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.24), lineWidth: 1)
        )
    }
}

struct SubCardBoxView<Content: View>: View {
    let borderColor: Color
    let backgroundColor: Color
    let content: Content

    init(
        borderColor: Color = Color.secondary.opacity(0.22),
        backgroundColor: Color = Color(nsColor: .textBackgroundColor),
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

struct ActionButtonView: View {
    let title: String
    let icon: String
    let variant: String // "primary", "secondary", "danger"
    let height: CGFloat
    let disabled: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String,
        variant: String = "secondary",
        height: CGFloat = 30,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.height = height
        self.disabled = disabled
        self.action = action
    }

    private var bgColor: Color {
        switch variant {
        case "primary": return Color.accentColor
        case "danger": return Color(nsColor: .systemRed)
        default: return Color(nsColor: .textBackgroundColor)
        }
    }

    private var fgColor: Color {
        switch variant {
        case "primary", "danger": return Color.white
        default: return Color.primary
        }
    }

    private var strokeColor: Color {
        switch variant {
        case "primary": return Color.accentColor.opacity(0.8)
        case "danger": return Color(nsColor: .systemRed).opacity(0.8)
        default: return Color.secondary.opacity(0.32)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(bgColor)
            .foregroundColor(fgColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .opacity(disabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .disabled(disabled)
    }
}

struct StatusPillView: View {
    let text: String
    let kind: String // "safe", "warn", "crit"

    var color: Color {
        switch kind {
        case "crit": return Color(nsColor: .systemRed)
        case "warn": return Color(nsColor: .systemOrange)
        default: return Color(nsColor: .systemGreen)
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.16))
            .foregroundColor(color)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(5)
    }
}

struct PadCounterGaugeRow: View {
    let pad: PadCounterItem
    let t: L10n

    var statusKind: String {
        if pad.percent >= 100 { return "crit" }
        if pad.percent >= 80 { return "warn" }
        return "safe"
    }

    var statusLabel: String {
        if pad.percent >= 100 { return t.statusCrit }
        if pad.percent >= 80 { return t.statusWarn }
        return t.statusSafe
    }

    var barColor: Color {
        switch statusKind {
        case "crit": return Color(nsColor: .systemRed)
        case "warn": return Color(nsColor: .systemOrange)
        default: return Color(nsColor: .systemGreen)
        }
    }

    var body: some View {
        SubCardBoxView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pad.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text("(\(pad.used) / \(pad.max) \(t.unitPoints))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    StatusPillView(text: "\(pad.percent)% • \(statusLabel)", kind: statusKind)
                }

                GeometryReader { geo in
                    let width = geo.size.width
                    let clampedPct = min(max(Double(pad.percent), 0.0), 100.0)
                    let fillWidth = width * (clampedPct / 100.0)
                    let warnX = width * 0.80

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.18))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(width: max(fillWidth, 0), height: 10)

                        Rectangle()
                            .fill(Color(nsColor: .systemOrange))
                            .frame(width: 2, height: 14)
                            .offset(x: warnX)
                    }
                }
                .frame(height: 14)
            }
        }
    }
}
