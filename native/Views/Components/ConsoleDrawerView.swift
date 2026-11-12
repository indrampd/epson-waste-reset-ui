import Cocoa
import SwiftUI

struct ConsoleDrawerView: View {
    @ObservedObject var vm: EWRViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(vm.t.consoleTitle)
                        .font(.system(size: 12, weight: .semibold))
                    Text("(\(vm.logs.count))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(vm.t.btnCopy) {
                        let full = vm.logs.map { "[\($0.timestamp)] [\($0.level.badgeText)] \($0.message)" }.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(full, forType: .string)
                    }
                    .controlSize(.small)

                    Button(vm.t.btnClear) {
                        vm.logs.removeAll()
                    }
                    .controlSize(.small)

                    Button(vm.isConsoleExpanded ? vm.t.btnClose : vm.t.btnOpen) {
                        vm.isConsoleExpanded.toggle()
                    }
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            if vm.isConsoleExpanded {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 3) {
                            ForEach(vm.logs) { item in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("[\(item.timestamp)]")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text(item.level.badgeText)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(item.level.color)
                                        .frame(width: 36, alignment: .leading)
                                    Text(item.message)
                                        .font(.system(size: 11, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 125)
                    .background(Color(nsColor: .textBackgroundColor))
                    .onChange(of: vm.logs.count) {
                        if let last = vm.logs.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}
