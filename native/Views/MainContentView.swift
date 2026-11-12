import Cocoa
import SwiftUI

struct MainContentView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderBarView(vm: vm)
            Divider()
            DeviceControlBarView(vm: vm)
            Divider()
            NavigationTabStripView(vm: vm)
            Divider()

            if let alertMsg = vm.alertMessage {
                AlertBannerView(message: alertMsg, level: vm.alertType) {
                    vm.hideAlert()
                }
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch vm.selectedTab {
                    case .dashboard:
                        DashboardTabView(vm: vm)
                    case .maintenance:
                        MaintenanceTabView(vm: vm)
                    case .info:
                        DiagnosticsTabView(vm: vm)
                    case .backup:
                        BackupRestoreTabView(vm: vm)
                    case .database:
                        DatabaseExplorerTabView(vm: vm)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            ConsoleDrawerView(vm: vm)
        }
        .sheet(isPresented: $vm.showDryRunSheet) {
            DryRunSheetView(vm: vm)
        }
        .sheet(isPresented: $vm.showResetSheet) {
            ResetConfirmationSheetView(vm: vm)
        }
    }
}

struct HeaderBarView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.14))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Epson Waste Reset")
                        .font(.system(size: 15, weight: .bold))
                    Text(vm.t.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Connection Status Pill (height: 28)
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isConnected ? Color(nsColor: .systemGreen) : Color(nsColor: .systemOrange))
                    .frame(width: 8, height: 8)
                Text(vm.connectionBadgeText)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
            )

            // Language Segmented Pill (height: 28)
            HStack(spacing: 0) {
                ForEach(AppLang.allCases, id: \.rawValue) { l in
                    let active = vm.lang == l
                    Button(action: { vm.setLanguage(l) }) {
                        Text(l.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 34, height: 28)
                            .background(active ? Color.accentColor : Color.clear)
                            .foregroundColor(active ? Color.white : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
            )

            // Theme Toggle Button (height: 28)
            Button(action: { vm.toggleTheme() }) {
                Image(systemName: vm.isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 32, height: 28)
                    .background(Color(nsColor: .textBackgroundColor))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(vm.lang == .id ? "Ganti Tema Terang/Gelap" : "Toggle Light/Dark Appearance")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct DeviceControlBarView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            // 1. Detected Device Dropdown (Pure SwiftUI Button + Popover for 100% consistent box styling)
            VStack(alignment: .leading, spacing: 5) {
                Text(vm.t.lblDevice)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Button(action: {
                    vm.isDeviceMenuOpen.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cable.connector.horizontal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(selectedDeviceLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(vm.devices.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .frame(width: 280, height: 30, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.32), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .popover(isPresented: $vm.isDeviceMenuOpen, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        if vm.devices.isEmpty {
                            Text(vm.t.noPrinterDetected)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(vm.devices) { dev in
                                let selected = vm.selectedDeviceId == dev.id
                                HStack(spacing: 8) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(selected ? .accentColor : .secondary)
                                    Text(dev.label)
                                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(width: 264, alignment: .leading)
                                .background(selected ? Color.accentColor.opacity(0.14) : Color.clear)
                                .cornerRadius(5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.selectedDeviceId = dev.id
                                    vm.handleDeviceSelectionChange()
                                    vm.isDeviceMenuOpen = false
                                }
                            }
                        }
                    }
                    .padding(6)
                    .focusEffectDisabled()
                }
            }

            // 2. Database Model Input Box (Identical 30pt height & border style)
            VStack(alignment: .leading, spacing: 5) {
                Text(vm.t.lblModel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField(vm.t.modelPlaceholder, text: $vm.modelOverride)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                    if !vm.modelOverride.isEmpty {
                        Button(action: { vm.modelOverride = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .frame(width: 260, height: 30, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.32), lineWidth: 1)
                )
            }

            Spacer()

            // 3. Action Buttons (Identical 30pt height & border style)
            HStack(spacing: 8) {
                ActionButtonView(
                    title: vm.t.btnRefreshDevices,
                    icon: "arrow.clockwise",
                    variant: "secondary",
                    height: 30,
                    disabled: vm.isScanningDevices || vm.isBusy
                ) {
                    Task { await vm.scanDevices(autoReadStatus: false) }
                }

                ActionButtonView(
                    title: vm.t.btnReadStatus,
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    variant: "primary",
                    height: 30,
                    disabled: vm.isBusy
                ) {
                    Task { await vm.readStatus() }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }

    private var selectedDeviceLabel: String {
        if let found = vm.devices.first(where: { $0.id == vm.selectedDeviceId }) {
            return found.label
        }
        return vm.t.noPrinterDetected
    }
}

struct NavigationTabStripView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        HStack(spacing: 8) {
            tabButton(.dashboard, title: vm.t.tabDashboard, icon: "speedometer")
            tabButton(.maintenance, title: vm.t.tabMaintenance, icon: "wrench.and.screwdriver")
            tabButton(.info, title: vm.t.tabInfo, icon: "cpu")
            tabButton(.backup, title: vm.t.tabBackup, icon: "externaldrive.badge.timemachine")
            tabButton(.database, title: "\(vm.t.tabDatabase) (\(vm.allModels.count))", icon: "list.bullet.rectangle")
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(_ tab: NavTab, title: String, icon: String) -> some View {
        let active = vm.selectedTab == tab
        return Button(action: {
            vm.selectedTab = tab
            if tab == .backup { vm.loadBackups() }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: active ? .semibold : .medium))
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(active ? Color.accentColor.opacity(0.16) : Color.clear)
            .foregroundColor(active ? .accentColor : .secondary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(active ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AlertBannerView: View {
    let message: String
    let level: LogLevel
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(level.color)
                .font(.system(size: 14, weight: .bold))
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(level.color.opacity(0.12))
    }

    private var iconName: String {
        switch level {
        case .error: return "exclamationmark.triangle.fill"
        case .warn: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
}
