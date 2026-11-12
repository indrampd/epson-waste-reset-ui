import Cocoa
import SwiftUI

struct DiagnosticsTabView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        CardContainerView {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.t.infoTitle)
                        .font(.system(size: 14, weight: .bold))
                    Text(vm.t.infoDesc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ActionButtonView(
                    title: vm.t.btnReloadInfo,
                    icon: "arrow.clockwise",
                    variant: "primary",
                    height: 30,
                    disabled: vm.isBusy
                ) {
                    Task { await vm.readHardwareInfo() }
                }
            }

            Divider()

            HStack(spacing: 12) {
                SubCardBoxView {
                    HStack(spacing: 6) {
                        Text("Serial Number:")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(vm.diagSerial)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                SubCardBoxView {
                    HStack(spacing: 6) {
                        Text("Firmware:")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(vm.diagFirmware)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.t.statsTitle)
                        .font(.system(size: 13, weight: .semibold))

                    if vm.diagCounters.isEmpty {
                        SubCardBoxView {
                            Text(vm.t.emptyStats)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 0) {
                            ForEach(vm.diagCounters) { item in
                                HStack {
                                    Text(item.formattedKey)
                                        .font(.system(size: 12))
                                    Spacer()
                                    Text(item.valueText)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.t.fatalTitle)
                        .font(.system(size: 13, weight: .semibold))

                    if vm.fatalErrors.isEmpty {
                        SubCardBoxView {
                            Text(vm.t.emptyFatal)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 0) {
                            ForEach(vm.fatalErrors) { f in
                                HStack {
                                    Text(f.slot)
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 65, alignment: .leading)
                                    Text(f.kind)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(f.code)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
