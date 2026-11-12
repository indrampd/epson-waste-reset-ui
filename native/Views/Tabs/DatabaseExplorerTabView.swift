import Cocoa
import SwiftUI

struct DatabaseExplorerTabView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        CardContainerView {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(vm.t.dbTitle) (\(vm.allModels.count) Printer)")
                        .font(.system(size: 14, weight: .bold))
                    Text(vm.t.dbDesc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                StatusPillView(text: "\(vm.totalMatchingModelsCount) cocok", kind: "safe")
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                TextField(vm.t.dbSearchPlaceholder, text: $vm.dbSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                if !vm.dbSearchQuery.isEmpty {
                    Button(action: { vm.dbSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.32), lineWidth: 1)
            )

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("Model").font(.system(size: 11, weight: .bold)).frame(width: 130, alignment: .leading)
                    Text("Aliases").font(.system(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Support").font(.system(size: 11, weight: .bold)).frame(width: 95, alignment: .leading)
                    Text("Cleanings").font(.system(size: 11, weight: .bold)).frame(width: 150, alignment: .leading)
                    Text("RKey / WKey").font(.system(size: 11, weight: .bold)).frame(width: 145, alignment: .leading)
                    Text("").frame(width: 80, alignment: .trailing)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08))

                Divider()

                LazyVStack(spacing: 0) {
                    ForEach(vm.filteredModels) { m in
                        HStack(spacing: 10) {
                            Text(m.name)
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 130, alignment: .leading)
                            Text(m.aliases.isEmpty ? "-" : m.aliases.joined(separator: ", "))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            StatusPillView(
                                text: m.isKeyless ? "Keyless" : (m.hasPadGroups ? "Resettable" : "Partial"),
                                kind: m.hasPadGroups ? "safe" : "warn"
                            )
                            .frame(width: 95, alignment: .leading)
                            Text(m.cleaningLevels.isEmpty ? "ESC/P2 Print" : m.cleaningLevels.joined(separator: ", "))
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .frame(width: 150, alignment: .leading)
                            Text("\(m.rkey) / \(m.wkey)")
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                                .frame(width: 145, alignment: .leading)
                            ActionButtonView(
                                title: vm.t.btnSelectModel,
                                icon: "checkmark.circle",
                                variant: "primary",
                                height: 24
                            ) {
                                vm.selectModelFromDatabase(m.name)
                            }
                            .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        Divider()
                    }
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
}
