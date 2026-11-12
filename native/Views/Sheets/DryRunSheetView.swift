import Cocoa
import SwiftUI

struct DryRunSheetView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(vm.t.dryrunModalTitle)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: { vm.showDryRunSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(vm.t.dryrunModalDesc)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Divider()

            if vm.isDryRunLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(vm.lang == .id ? "Memuat rencana simulasi penulisan EEPROM..." : "Loading EEPROM simulation plan...")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else if let err = vm.dryRunError {
                VStack(alignment: .leading, spacing: 8) {
                    Label(vm.lang == .id ? "Gagal Menjalankan Simulasi" : "Simulation Failed", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(nsColor: .systemRed))
                        .font(.system(size: 13, weight: .bold))
                    Text(err)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .systemRed).opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack(spacing: 20) {
                    Text("Model: \(vm.dryRunModel)").font(.system(size: 12, weight: .semibold))
                    Text("Covers: \(vm.dryRunCovers)").font(.system(size: 12)).foregroundColor(.secondary)
                    Spacer()
                    Text("\(vm.plannedWrites.count) registers").font(.system(size: 12, weight: .bold, design: .monospaced))
                }

                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("EEPROM Address (Dec / Hex)").font(.system(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                            Text("Planned Reset Value (Dec / Hex)").font(.system(size: 11, weight: .bold)).frame(width: 220, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))

                        Divider()

                        ForEach(vm.plannedWrites) { w in
                            HStack {
                                Text(String(format: "Register %d (0x%04X)", w.address, w.address))
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(String(format: "%d (0x%02X)", w.value, w.value))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .frame(width: 220, alignment: .trailing)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
                .frame(minHeight: 180, maxHeight: 260)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }

            Divider()

            HStack {
                Spacer()
                Button(vm.t.btnClose) {
                    vm.showDryRunSheet = false
                }
                if vm.dryRunError == nil && !vm.isDryRunLoading {
                    Button(role: .destructive, action: {
                        vm.showDryRunSheet = false
                        vm.prepareResetSheet()
                    }) {
                        Text(vm.t.btnProceedReset)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(nsColor: .systemRed))
                }
            }
        }
        .padding(20)
        .frame(width: 560)
    }
}
