import Cocoa
import SwiftUI

struct BackupRestoreTabView: View {
    @ObservedObject var vm: EWRViewModel

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        CardContainerView {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.t.backupTitle)
                        .font(.system(size: 14, weight: .bold))
                    Text(vm.t.backupDesc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    ActionButtonView(
                        title: vm.t.btnOpenBackupFolder,
                        icon: "folder",
                        variant: "secondary",
                        height: 30
                    ) {
                        vm.revealBackupsInFinder()
                    }
                    ActionButtonView(
                        title: vm.t.btnReloadBackups,
                        icon: "arrow.clockwise",
                        variant: "secondary",
                        height: 30
                    ) {
                        vm.loadBackups()
                    }
                    ActionButtonView(
                        title: vm.t.btnDumpEeprom,
                        icon: "square.and.arrow.down",
                        variant: "primary",
                        height: 30,
                        disabled: vm.isBusy
                    ) {
                        Task { await vm.dumpEepromBackup() }
                    }
                }
            }

            Divider()

            if vm.backups.isEmpty {
                SubCardBoxView {
                    Text(vm.t.emptyBackups)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Filename").font(.system(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Size").font(.system(size: 11, weight: .bold)).frame(width: 80, alignment: .leading)
                        Text("Created").font(.system(size: 11, weight: .bold)).frame(width: 160, alignment: .leading)
                        Text("Actions").font(.system(size: 11, weight: .bold)).frame(width: 170, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.08))

                    Divider()

                    ForEach(vm.backups) { b in
                        HStack {
                            Text(b.filename)
                                .font(.system(size: 12, design: .monospaced))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(format: "%.1f KB", Double(b.sizeBytes) / 1024.0))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(dateFormatter.string(from: b.created))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 160, alignment: .leading)
                            HStack(spacing: 6) {
                                ActionButtonView(
                                    title: "Dry Run",
                                    icon: "doc.text.magnifyingglass",
                                    variant: "secondary",
                                    height: 26,
                                    disabled: vm.isBusy
                                ) {
                                    Task { await vm.restoreBackup(b, dryRun: true) }
                                }

                                ActionButtonView(
                                    title: "Restore",
                                    icon: "arrow.uturn.backward",
                                    variant: "primary",
                                    height: 26,
                                    disabled: vm.isBusy
                                ) {
                                    vm.selectedRestoreItem = b
                                }
                            }
                            .frame(width: 170, alignment: .trailing)
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
        .alert("Restore EEPROM Backup", isPresented: Binding(
            get: { vm.selectedRestoreItem != nil },
            set: { if !$0 { vm.selectedRestoreItem = nil } }
        )) {
            Button(vm.t.btnCancel, role: .cancel) { vm.selectedRestoreItem = nil }
            Button("Restore", role: .destructive) {
                if let item = vm.selectedRestoreItem {
                    vm.selectedRestoreItem = nil
                    Task { await vm.restoreBackup(item, dryRun: false) }
                }
            }
        } message: {
            Text(vm.lang == .id
                 ? "Kembalikan nilai counter printer dari file backup \"\(vm.selectedRestoreItem?.filename ?? "")\"?"
                 : "Restore printer counter values from backup file \"\(vm.selectedRestoreItem?.filename ?? "")\"?")
        }
    }
}
