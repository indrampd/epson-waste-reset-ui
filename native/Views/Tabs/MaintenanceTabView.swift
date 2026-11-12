import Cocoa
import SwiftUI

struct MaintenanceTabView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        CardContainerView {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.t.cardMaintenanceTitle)
                    .font(.system(size: 14, weight: .bold))
                Text(vm.t.cardMaintenanceDesc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            SubCardBoxView {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.t.maintNozzleTitle)
                            .font(.system(size: 13, weight: .semibold))
                        Text(vm.t.maintNozzleDesc)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Toggle(vm.lang == .id ? "Gunakan pola alternatif (alt)" : "Use alternate pattern (alt)", isOn: $vm.nozzleVariantAlt)
                            .font(.system(size: 11))
                    }
                    Spacer()
                    ActionButtonView(
                        title: vm.t.btnPrintNozzle,
                        icon: "doc.viewfinder",
                        variant: "secondary",
                        height: 32,
                        disabled: vm.isBusy
                    ) {
                        Task { await vm.runMaintenance(action: "nozzle-check") }
                    }
                }
            }

            SubCardBoxView {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.t.maintCleanTitle)
                            .font(.system(size: 13, weight: .semibold))
                        Text(vm.t.maintCleanDesc)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Text(vm.t.cleanLevelLbl)
                                    .font(.system(size: 12))
                                Picker("", selection: $vm.cleanLevel) {
                                    Text("Normal").tag("normal")
                                    Text("Gentle").tag("gentle")
                                    Text("Medium").tag("medium")
                                    Text("Strong").tag("strong")
                                }
                                .labelsHidden()
                                .frame(width: 110)
                            }

                            HStack(spacing: 6) {
                                Text(vm.t.cleanGroupLbl)
                                    .font(.system(size: 12))
                                Picker("", selection: $vm.cleanGroup) {
                                    Text("All").tag("all")
                                    Text("Black").tag("black")
                                    Text("Color").tag("color")
                                }
                                .labelsHidden()
                                .frame(width: 95)
                            }
                        }
                    }
                    Spacer()
                    ActionButtonView(
                        title: vm.t.btnRunClean,
                        icon: "drop.triangle",
                        variant: "secondary",
                        height: 32,
                        disabled: vm.isBusy
                    ) {
                        Task { await vm.runMaintenance(action: "head-clean") }
                    }
                }
            }

            SubCardBoxView(
                borderColor: Color(nsColor: .systemRed).opacity(0.4),
                backgroundColor: Color(nsColor: .systemRed).opacity(0.06)
            ) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.t.maintPowerTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(nsColor: .systemRed))
                        Text(vm.t.maintPowerDesc)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ActionButtonView(
                        title: vm.t.btnRunPowerClean,
                        icon: "bolt.trianglebadge.exclamationmark.fill",
                        variant: "danger",
                        height: 32,
                        disabled: vm.isBusy
                    ) {
                        vm.confirmPowerClean = true
                    }
                }
            }
        }
        .alert(vm.t.maintPowerTitle, isPresented: $vm.confirmPowerClean) {
            Button(vm.t.btnCancel, role: .cancel) {}
            Button(vm.t.btnRunPowerClean, role: .destructive) {
                Task { await vm.runMaintenance(action: "power-clean") }
            }
        } message: {
            Text(vm.t.maintPowerDesc)
        }
    }
}
