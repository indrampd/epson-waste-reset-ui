import Cocoa
import SwiftUI

struct ResetConfirmationSheetView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(vm.t.resetModalTitle, systemImage: "exclamationmark.shield.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(nsColor: .systemRed))
                Spacer()
                if !vm.isResetInProgress || vm.resetFinishedOk != nil {
                    Button(action: { vm.showResetSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            if !vm.isResetInProgress {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.t.resetWarnTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(nsColor: .systemOrange))
                        Text(vm.t.resetWarnText)
                            .font(.system(size: 12))
                    }
                    .padding(12)
                    .background(Color(nsColor: .systemOrange).opacity(0.12))
                    .cornerRadius(8)

                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target Model:").font(.system(size: 11)).foregroundColor(.secondary)
                            Text(vm.modelOverride.isEmpty ? (vm.printerName != "-" ? vm.printerName : "Otomatis") : vm.modelOverride)
                                .font(.system(size: 13, weight: .bold))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.t.lblPrinterConn).font(.system(size: 11)).foregroundColor(.secondary)
                            Text(vm.printerConn).font(.system(size: 13, weight: .bold))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                    Toggle(isOn: $vm.confirmPowerCycle) {
                        Text(vm.t.chkConfirmLabel)
                            .font(.system(size: 12, weight: .medium))
                    }

                    Toggle(isOn: $vm.forceYesReset) {
                        Text(vm.lang == .id
                             ? "Paksa penulisan (--force-yes) jika ada ketidakcocokan nama seri"
                             : "Force write (--force-yes) if model alias/error gate triggers")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                HStack {
                    Spacer()
                    Button(vm.t.btnCancel) {
                        vm.showResetSheet = false
                    }
                    Button(role: .destructive, action: {
                        Task { await vm.executeReset() }
                    }) {
                        Text(vm.t.btnConfirmReset)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(nsColor: .systemRed))
                    .disabled(!vm.confirmPowerCycle)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(vm.t.resetProgressTitle)
                        .font(.system(size: 13, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        stepRow(num: 1, title: vm.t.step1, state: vm.step1State)
                        stepRow(num: 2, title: vm.t.step2, state: vm.step2State)
                        stepRow(num: 3, title: vm.t.step3, state: vm.step3State)
                        stepRow(num: 4, title: vm.t.step4, state: vm.step4State)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    if let ok = vm.resetFinishedOk {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: ok ? "checkmark.seal.fill" : "xmark.octagon.fill")
                                .foregroundColor(ok ? Color(nsColor: .systemGreen) : Color(nsColor: .systemRed))
                                .font(.system(size: 16))
                            Text(vm.resetResultMessage)
                                .font(.system(size: 12, weight: .medium))
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((ok ? Color(nsColor: .systemGreen) : Color(nsColor: .systemRed)).opacity(0.14))
                        .cornerRadius(8)

                        HStack {
                            Spacer()
                            Button(vm.t.btnClose) {
                                vm.showResetSheet = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func stepRow(num: Int, title: String, state: StepState) -> some View {
        HStack(spacing: 10) {
            Group {
                switch state {
                case .pending:
                    Text("\(num)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                case .active:
                    ProgressView()
                        .controlSize(.small)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(nsColor: .systemGreen))
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(nsColor: .systemRed))
                }
            }
            .frame(width: 20, height: 20)

            Text(title)
                .font(.system(size: 12, weight: state == .active ? .semibold : .regular))
                .foregroundColor(state == .pending ? .secondary : .primary)
        }
    }
}
