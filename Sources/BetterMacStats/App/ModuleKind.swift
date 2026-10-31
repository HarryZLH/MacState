import Foundation

/// The set of menu bar modules the app can display. Each maps to one reader and
/// one NSStatusItem.
enum ModuleKind: String, CaseIterable, Codable, Identifiable {
    case cpu, gpu, memory, disk, network, battery, sensors, bluetooth, clock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .memory: return L("内存")
        case .disk: return L("磁盘")
        case .network: return L("网络")
        case .battery: return L("电池")
        case .sensors: return L("传感器")
        case .bluetooth: return L("蓝牙")
        case .clock: return L("时钟")
        }
    }

    /// SF Symbol name. Rendered with a nil-safe lookup, so an unavailable symbol
    /// simply shows no icon instead of crashing.
    var symbol: String {
        switch self {
        case .cpu: return "cpu"
        case .gpu: return "cube.transparent"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        case .battery: return "battery.100"
        case .sensors: return "thermometer.medium"
        case .bluetooth: return "dot.radiowaves.right"
        case .clock: return "clock"
        }
    }

    /// Default module selection; persisted user choices always take precedence.
    var enabledByDefault: Bool {
        switch self {
        case .cpu, .gpu, .memory, .disk, .network, .sensors: return true
        case .battery, .bluetooth, .clock: return false
        }
    }

    /// Natural left-to-right order in the menu bar.
    static let defaultOrder: [ModuleKind] = [.cpu, .gpu, .memory, .disk, .network, .sensors, .battery, .bluetooth, .clock]
}
