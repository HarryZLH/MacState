import SwiftUI
import BetterMacStatsCore

// MARK: - Battery

struct BatteryPopover: View {
    @ObservedObject var engine: StatsEngine
    @ObservedObject var settings: AppSettings
    var onOpenSettings: () -> Void

    var body: some View {
        let b = engine.battery
        PopoverScaffold(title: "电池", systemImage: "battery.100", onOpenSettings: onOpenSettings) {
            if !b.isPresent {
                EmptyState(text: "没有内置电池，此 Mac 使用外接电源。")
            } else {
                let frac = Double(b.percentage) / 100.0
                let color = b.isCharging ? Color.green : Severity.battery(b.percentage).fill
                HStack(spacing: 14) {
                    RingGauge(fraction: frac, color: color,
                              label: "\(b.percentage)%", caption: b.isCharging ? "充电中" : nil)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 5) {
                        StatRow("状态", statusText(b))
                        if b.isCharging, let f = b.timeToFullMinutes {
                            StatRow("充满还需", Formatting.duration(minutes: f))
                        } else if let e = b.timeToEmptyMinutes {
                            StatRow("剩余时间", Formatting.duration(minutes: e))
                        }
                        if let t = b.temperature { StatRow("温度", formatTemp(t, settings)) }
                    }
                }
                Divider()
                if let h = b.healthPercent { StatRow("健康度", "\(h)%", color: Severity.health(h).text) }
                if let c = b.cycleCount { StatRow("循环次数", "\(c)") }
                if let cond = b.conditionString { StatRow("电池状况", cond) }
                if let mx = b.maxCapacity, let dz = b.designCapacity {
                    StatRow("容量", "\(mx) / \(dz) mAh")
                }
            }
        }
    }

    private func statusText(_ b: BatteryInfo) -> String {
        if b.isCharged { return "已充满" }
        if b.isCharging { return "正在充电" }
        return b.onACPower ? "使用外接电源（未充电）" : "使用电池"
    }
}

// MARK: - Sensors

struct SensorsPopover: View {
    @ObservedObject var engine: StatsEngine
    @ObservedObject var settings: AppSettings
    var onOpenSettings: () -> Void

    var body: some View {
        PopoverScaffold(title: "传感器", systemImage: "thermometer.medium", onOpenSettings: onOpenSettings) {
            if engine.sensors.isEmpty {
                EmptyState(text: "此 Mac 未提供传感器数据。")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    group("温度", engine.temperatureSensors)
                    group("风扇", engine.fanSensors)
                    group("功率", engine.powerSensors)
                }
            }
        }
    }

    @ViewBuilder
    private func group(_ title: String, _ readings: [SensorReading]) -> some View {
        if !readings.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel(text: title)
                ForEach(SensorGroup.make(readings), id: \.name) { g in
                    StatRow(g.count > 1 ? "\(g.name) ×\(g.count)" : g.name,
                            // Show the max only when it says something the average does not.
                            g.max - g.average >= 1 ? "\(value(g.kind, g.average)) · 最高 \(value(g.kind, g.max))"
                                        : value(g.kind, g.average),
                            color: g.kind == .temperature ? Severity.temperature(g.max).text : nil)
                }
            }
        }
    }

    private func value(_ kind: SensorKind, _ v: Double) -> String {
        switch kind {
        case .temperature: return formatTemp(v, settings)
        case .fan: return "\(Int(v)) RPM"
        case .power: return String(format: "%.1f W", v)
        default: return String(format: "%.1f", v)
        }
    }
}

// MARK: - Bluetooth

struct BluetoothPopover: View {
    @ObservedObject var engine: StatsEngine
    @ObservedObject var settings: AppSettings
    var onOpenSettings: () -> Void

    var body: some View {
        PopoverScaffold(title: "蓝牙", systemImage: "dot.radiowaves.right", onOpenSettings: onOpenSettings) {
            if engine.bluetooth.isEmpty {
                EmptyState(text: "没有已配对的蓝牙设备。")
            } else {
                let devices = engine.bluetooth.sorted { $0.isConnected && !$1.isConnected }
                // Scroll only for long lists; a ScrollView would otherwise fill
                // its whole max height and leave a blank block under a few devices.
                ScrollIfNeeded(devices.count > 8, maxHeight: 300) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(devices) { dev in
                            HStack(spacing: 8) {
                                Circle().fill(dev.isConnected ? Color.green : Color.secondary.opacity(0.4))
                                    .frame(width: 7, height: 7)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(dev.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                    Text(dev.kind).font(.system(size: 10)).foregroundColor(.secondary)
                                }
                                Spacer()
                                if let pct = dev.batteryPercent {
                                    Text("\(pct)%").font(.system(size: 11))
                                } else if let rssi = dev.rssi, dev.isConnected {
                                    Text("\(rssi) dBm").font(.system(size: 10)).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Clock

struct ClockPopover: View {
    @ObservedObject var engine: StatsEngine
    @ObservedObject var settings: AppSettings
    var onOpenSettings: () -> Void

    var body: some View {
        PopoverScaffold(title: "时钟", systemImage: "clock", onOpenSettings: onOpenSettings) {
            if engine.clocks.isEmpty {
                EmptyState(text: "请在设置中添加时区。")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(engine.clocks) { c in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(c.label).font(.system(size: 12, weight: .medium))
                                Text("\(c.date) · \(c.offsetDescription)")
                                    .font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(c.time).font(.system(size: 20, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }
}

struct ScrollIfNeeded<Content: View>: View {
    var scrolls: Bool
    var maxHeight: CGFloat
    @ViewBuilder var content: () -> Content

    init(_ scrolls: Bool, maxHeight: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.scrolls = scrolls
        self.maxHeight = maxHeight
        self.content = content
    }

    var body: some View {
        if scrolls {
            ScrollView { content() }.frame(height: maxHeight)
        } else {
            content()
        }
    }
}
