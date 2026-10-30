import AppKit
import SwiftUI
import BetterMacStatsCore

/// Native preferences window: icon tabs in the toolbar, one fixed-size pane per tab.
final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings) {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        func add<V: View>(_ title: String, _ symbol: String, height: CGFloat, _ view: V) {
            let pane = NSHostingController(rootView: view.frame(width: Self.width, height: height))
            pane.title = title
            pane.preferredContentSize = NSSize(width: Self.width, height: height)
            let item = NSTabViewItem(viewController: pane)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            tabs.addTabViewItem(item)
        }
        add("通用", "gearshape", height: 170, GeneralTab(settings: settings))
        add("模块", "square.grid.2x2", height: 430, ModulesTab(settings: settings))
        add("外观", "paintbrush", height: 270, AppearanceTab(settings: settings))
        add("时钟", "clock", height: 430, ClockTab(settings: settings))
        add("关于", "info.circle", height: 380, AboutTab())

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    private static let width: CGFloat = 500

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        if window?.isVisible == false { window?.center() }
        window?.makeKeyAndOrderFront(nil)
    }
}

private extension View {
    /// System Settings-style grouped rows on macOS 13+; padded columns on macOS 12.
    @ViewBuilder func groupedForm() -> some View {
        if #available(macOS 13.0, *) {
            formStyle(.grouped)
        } else {
            padding(20)
        }
    }
}

/// A rounded, tinted symbol tile, as System Settings uses for its rows.
private struct IconTile: View {
    var symbol: String
    var color: Color
    var size: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .fill(LinearGradient(colors: [color.opacity(0.8), color], startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
            .overlay(Image(systemName: symbol)
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundColor(.white))
    }
}

// MARK: - General

private struct GeneralTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("登录时启动", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
            }
            Section {
                Picker("刷新间隔", selection: $settings.refreshInterval) {
                    ForEach(AppSettings.refreshIntervalOptions, id: \.self) { v in
                        Text(intervalLabel(v)).tag(v)
                    }
                }
            } footer: {
                Text("降低刷新频率可减少 CPU 和电池消耗。关闭的模块不会采集数据。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .groupedForm()
    }

    private func intervalLabel(_ v: Double) -> String {
        v < 1 ? "\(Int(v * 1000)) 毫秒" : v == 1 ? "1 秒" : "\(Int(v)) 秒"
    }
}

// MARK: - Modules

private struct ModulesTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择菜单栏显示的模块，拖动可调整顺序。")
                .font(.callout).foregroundColor(.secondary)
            List {
                ForEach(settings.moduleOrder) { kind in
                    HStack(spacing: 10) {
                        IconTile(symbol: kind.symbol, color: kind.tint)
                        Text(kind.title)
                        Spacer()
                        Toggle(kind.title, isOn: binding(for: kind))
                            .labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    .padding(.vertical, 3)
                }
                .onMove { source, destination in
                    settings.moduleOrder.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.1)))
        }
        .padding(20)
    }

    private func binding(for kind: ModuleKind) -> Binding<Bool> {
        Binding(get: { settings.isEnabled(kind) }, set: { settings.setEnabled(kind, $0) })
    }
}

private extension ModuleKind {
    var tint: Color {
        switch self {
        case .cpu: return .blue
        case .gpu: return .purple
        case .memory: return .green
        case .disk: return .gray
        case .network: return .teal
        case .battery: return .mint
        case .sensors: return .orange
        case .bluetooth: return .indigo
        case .clock: return .red
        }
    }
}

// MARK: - Appearance

private struct AppearanceTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("显示图标", isOn: $settings.showMenuBarIcons)
                Toggle("根据负载用颜色标记数值", isOn: $settings.colorCoded)
            } header: {
                Text("菜单栏")
            }
            .toggleStyle(.switch)
            Section {
                Picker("网络速度", selection: $settings.networkInBits) {
                    Text("字节（MB/s）").tag(false)
                    Text("比特（Mbps）").tag(true)
                }
                Picker("温度", selection: $settings.useFahrenheit) {
                    Text("摄氏度（°C）").tag(false)
                    Text("华氏度（°F）").tag(true)
                }
            } header: {
                Text("单位")
            }
        }
        .groupedForm()
    }
}

// MARK: - Clock

private struct ClockTab: View {
    @ObservedObject var settings: AppSettings
    private let zoneIDs = TimeZone.knownTimeZoneIdentifiers.sorted()

    var body: some View {
        Form {
            if settings.clockZones.isEmpty {
                Section {
                    Text("尚未添加时钟。添加后可在菜单栏显示时间。")
                        .foregroundColor(.secondary)
                }
            }
            ForEach(settings.clockZones) { zone in
                Section {
                    TextField("名称", text: binding(zone.id, \.label, ""))
                    Picker("时区", selection: binding(zone.id, \.timeZoneID, zone.timeZoneID)) {
                        ForEach(zoneIDs, id: \.self) { Text(zoneName($0)).tag($0) }
                    }
                    Toggle("24 小时制", isOn: binding(zone.id, \.use24Hour, true))
                    Toggle("显示秒数", isOn: binding(zone.id, \.showSeconds, false))
                } header: {
                    HStack {
                        Text(zone.label.isEmpty ? "时钟" : zone.label)
                        Spacer()
                        Button(role: .destructive) {
                            settings.clockZones.removeAll { $0.id == zone.id }
                        } label: {
                            Label("移除", systemImage: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("移除此时钟")
                    }
                }
                .toggleStyle(.switch)
            }
            Section {
                Button {
                    settings.clockZones.append(ClockZone(label: "新时钟", timeZoneID: TimeZone.current.identifier))
                } label: {
                    Label("添加时钟", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            } footer: {
                Text("菜单栏显示第一个时钟；点击后可查看所有时钟。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .groupedForm()
    }

    private func zoneName(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "/", with: " / ")
    }

    /// Looks the zone up by id on every access. `ForEach($array)` bindings capture
    /// an index, so deleting a row while one of its fields is live can crash.
    private func binding<Value>(_ id: UUID, _ keyPath: WritableKeyPath<ClockZone, Value>,
                                _ fallback: Value) -> Binding<Value> {
        Binding(
            get: { settings.clockZones.first { $0.id == id }?[keyPath: keyPath] ?? fallback },
            set: { value in
                guard let i = settings.clockZones.firstIndex(where: { $0.id == id }) else { return }
                settings.clockZones[i][keyPath: keyPath] = value
            })
    }
}

// MARK: - About

private struct AboutTab: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)
            VStack(spacing: 3) {
                Text("MacState 性能监控").font(.title2).fontWeight(.semibold)
                Text("版本 \(version)").font(.callout).foregroundColor(.secondary)
            }
            Text("轻量的原生菜单栏监控工具，支持 CPU、GPU、内存、磁盘、网络、电池、传感器、蓝牙和世界时钟。")
                .font(.callout).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 360)
            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/ariwisnu/better-mac-stats")!)
                Link("反馈问题", destination: URL(string: "https://github.com/HarryZLH/MacState/issues")!)
            }
            .font(.callout)
            .padding(.top, 4)
            Text("基于 Better Mac Stats · 原作者 Putu Ari Wisnu 及贡献者")
                .font(.caption).foregroundColor(.secondary)
            Button("查看 MIT 开源许可证") {
                if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
