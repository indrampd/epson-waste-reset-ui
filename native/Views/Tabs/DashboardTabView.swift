import Cocoa
import SwiftUI

struct DashboardTabView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Printer Status Card
            CardContainerView {
                HStack {
                    Text(vm.t.cardPrinterStatus)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    StatusPillView(text: vm.printerStateBadge, kind: stateKind(vm.printerStateBadge))
                }

                Divider()

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12, alignment: .leading),
                    GridItem(.flexible(), spacing: 12, alignment: .leading),
                    GridItem(.flexible(), spacing: 12, alignment: .leading),
                    GridItem(.flexible(), spacing: 12, alignment: .leading)
                ], spacing: 12) {
                    summaryField(label: vm.t.lblPrinterName, value: vm.printerName)
                    summaryField(label: vm.t.lblPrinterConn, value: vm.printerConn)
                    summaryField(label: vm.t.lblPrinterCondition, value: vm.printerCondition)
                    summaryField(label: vm.t.lblDeviceId, value: vm.deviceIdString, monospaced: true)
                }
            }

            // 2. Waste Ink Pad Counters & Ink Levels Card
            CardContainerView {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.t.cardWasteCounters)
                            .font(.system(size: 14, weight: .bold))
                        Text(vm.t.descWasteCounters)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ActionButtonView(
                        title: vm.t.btnRefresh,
                        icon: "arrow.clockwise",
                        variant: "secondary",
                        height: 28,
                        disabled: vm.isBusy
                    ) {
                        Task { await vm.readStatus() }
                    }
                }

                Divider()

                ForEach(vm.pads) { pad in
                    PadCounterGaugeRow(pad: pad, t: vm.t)
                }

                if !vm.inks.isEmpty {
                    let isTankMode = vm.inks.allSatisfy { $0.isEcoTankVisual }
                    Divider()
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(isTankMode ? vm.t.inkTankTitle : vm.t.inkLevelsTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(isTankMode
                                 ? (vm.lang == .id ? "Mode: Kalibrasi Visual" : "Mode: Visual Calibration")
                                 : (vm.lang == .id ? "Mode: Sensor Chip IC (Otomatis)" : "Mode: IC Chip Sensor (Auto)"))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(isTankMode ? .secondary : Color(nsColor: .systemGreen))
                        }
                        if isTankMode {
                            Text(vm.t.inkTankDesc)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: min(max(vm.inks.count, 1), 4)),
                        spacing: 12
                    ) {
                        ForEach(vm.inks) { ink in
                            SubCardBoxView {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(inkSwatchColor(ink.color))
                                            .frame(width: 10, height: 10)
                                            .overlay(
                                                Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1)
                                            )
                                        Text(ink.color)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer(minLength: 6)
                                        Text(ink.isEcoTankVisual ? "~\(ink.effectiveLevel)%" : "\(ink.effectiveLevel)%")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }

                                    if ink.isEcoTankVisual {
                                        HStack(spacing: 4) {
                                            ForEach([20, 40, 60, 80, 100], id: \.self) { step in
                                                let filled = ink.effectiveLevel >= step
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(filled ? inkSwatchColor(ink.color) : Color.secondary.opacity(0.18))
                                                    .frame(height: 10)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                                                    )
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        vm.setManualTankLevel(for: ink.color, level: step)
                                                    }
                                                    .help("Set \(ink.color) tank level to \(step)%")
                                            }
                                        }
                                    } else {
                                        GeometryReader { geo in
                                            let w = geo.size.width
                                            let ratio = min(max(Double(ink.effectiveLevel) / 100.0, 0.0), 1.0)
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.secondary.opacity(0.18))
                                                    .frame(height: 10)
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(inkSwatchColor(ink.color))
                                                    .frame(width: max(w * ratio, 0), height: 10)
                                            }
                                        }
                                        .frame(height: 10)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. Reset Actions Control Center Card
            CardContainerView {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.t.cardActions)
                        .font(.system(size: 14, weight: .bold))
                    Text(vm.t.descActions)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack(spacing: 12) {
                    ActionButtonView(
                        title: vm.t.btnDryRun,
                        icon: "doc.text.magnifyingglass",
                        variant: "secondary",
                        height: 34,
                        disabled: vm.isBusy
                    ) {
                        Task { await vm.openAndRunDryRun() }
                    }

                    ActionButtonView(
                        title: vm.t.btnDoReset,
                        icon: "arrow.counterclockwise.circle.fill",
                        variant: "danger",
                        height: 34,
                        disabled: vm.isBusy
                    ) {
                        vm.prepareResetSheet()
                    }
                }

                SubCardBoxView {
                    VStack(alignment: .leading, spacing: 6) {
                        safetyRow(badge: vm.t.safety1Title, text: vm.t.safety1Desc)
                        safetyRow(badge: vm.t.safety2Title, text: vm.t.safety2Desc)
                    }
                }
            }
        }
    }

    private func summaryField(label: String, value: String, monospaced: Bool = false) -> some View {
        SubCardBoxView {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(monospaced ? .system(size: 11, design: .monospaced) : .system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .textSelection(.enabled)
            }
        }
    }

    private func safetyRow(badge: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(badge)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.16))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private func stateKind(_ st: String) -> String {
        let u = st.uppercased()
        if u.contains("ERR") || u.contains("FATAL") { return "crit" }
        if u.contains("WARN") || u.contains("BUSY") { return "warn" }
        return "safe"
    }

    private func inkSwatchColor(_ name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("black") || lower.contains("bk") {
            return Color(red: 0.15, green: 0.15, blue: 0.17)
        } else if lower.contains("light cyan") || lower.contains("lc") {
            return Color(red: 0.45, green: 0.85, blue: 0.98)
        } else if lower.contains("cyan") {
            return Color(red: 0.0, green: 0.68, blue: 0.94)
        } else if lower.contains("light magenta") || lower.contains("lm") {
            return Color(red: 0.96, green: 0.55, blue: 0.78)
        } else if lower.contains("magenta") {
            return Color(red: 0.93, green: 0.0, blue: 0.55)
        } else if lower.contains("yellow") {
            return Color(red: 1.0, green: 0.82, blue: 0.0)
        } else if lower.contains("grey") || lower.contains("gray") {
            return Color.gray
        }
        return Color.accentColor
    }
}
