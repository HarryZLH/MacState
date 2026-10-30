import Foundation
import Combine

final class AppLanguage: ObservableObject {
    static let shared = AppLanguage()
    @Published var followsSystem: Bool {
        didSet { UserDefaults.standard.set(followsSystem, forKey: "languageFollowsSystem") }
    }
    @Published var selected: String {
        didSet { UserDefaults.standard.set(selected, forKey: "interfaceLanguage") }
    }
    private var observer: NSObjectProtocol?
    private init() {
        followsSystem = UserDefaults.standard.object(forKey: "languageFollowsSystem") as? Bool ?? true
        selected = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "zh-Hans"
        observer = NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in self?.objectWillChange.send() }
    }
    var isChinese: Bool {
        let languages = followsSystem ? Locale.preferredLanguages : [selected]
        return Bundle.preferredLocalizations(from: ["en", "zh-Hans"], forPreferences: languages).first == "zh-Hans"
    }
    func text(_ key: String) -> String { isChinese ? key : Self.english[key] ?? key }
    private static let english: [String: String] = [
        "版本": "Version",
        "内存": "Memory",
        "磁盘": "Disk",
        "网络": "Network",
        "电池": "Battery",
        "传感器": "Sensors",
        "蓝牙": "Bluetooth",
        "时钟": "Clock",
        "通用": "General",
        "模块": "Modules",
        "外观": "Appearance",
        "关于": "About",
        "登录时启动": "Launch at Login",
        "刷新间隔": "Update interval",
        "降低刷新频率可减少 CPU 和电池消耗。关闭的模块不会采集数据。": "A slower interval uses less CPU and battery. Disabled modules are not polled at all.",
        "1 秒": "1 second",
        "选择菜单栏显示的模块，拖动可调整顺序。": "Choose what appears in the menu bar. Drag to change the order.",
        "显示图标": "Show icons",
        "根据负载用颜色标记数值": "Color-code values by load",
        "菜单栏": "Menu Bar",
        "网络速度": "Network speed",
        "字节（MB/s）": "Bytes (MB/s)",
        "比特（Mbps）": "Bits (Mbps)",
        "温度": "Temperatures",
        "摄氏度（°C）": "Celsius (°C)",
        "华氏度（°F）": "Fahrenheit (°F)",
        "单位": "Units",
        "尚未添加时钟。添加后可在菜单栏显示时间。": "No clocks yet. Add one to show the time in the menu bar.",
        "名称": "Name",
        "时区": "Time zone",
        "24 小时制": "24-hour time",
        "显示秒数": "Show seconds",
        "移除": "Remove",
        "移除此时钟": "Remove this clock",
        "新时钟": "New Clock",
        "添加时钟": "Add Clock",
        "菜单栏显示第一个时钟；点击后可查看所有时钟。": "The first clock is shown in the menu bar; all of them appear in its popover.",
        "轻量的原生菜单栏监控工具，支持 CPU、GPU、内存、磁盘、网络、电池、传感器、蓝牙和世界时钟。": "A lightweight, native menu bar monitor for CPU, GPU, memory, disk, network, battery, sensors, Bluetooth and world clocks.",
        "反馈问题": "Report an Issue",
        "MIT 许可证": "MIT License",
        "设置…": "Settings…",
        "退出": "Quit",
        "退出 Better Mac Stats": "Quit Better Mac Stats",
        "没有内置电池，此 Mac 使用外接电源。": "No internal battery — this Mac runs on AC power.",
        "充电中": "charging",
        "状态": "Status",
        "充满还需": "Time to full",
        "剩余时间": "Time remaining",
        "健康度": "Health",
        "循环次数": "Cycle count",
        "电池状况": "Condition",
        "容量": "Capacity",
        "已充满": "Charged",
        "正在充电": "Charging",
        "使用外接电源（未充电）": "On AC (not charging)",
        "使用电池": "On battery",
        "此 Mac 未提供传感器数据。": "No sensor data is exposed on this Mac.",
        "风扇": "Fans",
        "功率": "Power",
        "没有已配对的蓝牙设备。": "No paired Bluetooth devices.",
        "请在设置中添加时区。": "Add a time zone in Settings.",
        "负载": "load",
        "系统": "System",
        "用户": "User",
        "核心": "Cores",
        "各核心负载": "Per-core",
        "此 Mac 暂无 GPU 数据。": "No GPU data available on this Mac.",
        "使用率": "Utilization",
        "显存占用": "VRAM in use",
        "已用": "Used",
        "可用": "available",
        "内存压力": "Pressure",
        "总计": "Total",
        "应用": "App",
        "联动内存": "Wired",
        "已压缩": "Compressed",
        "已缓存": "Cached",
        "交换空间": "Swap",
        "正常": "Normal",
        "建议维修": "Service recommended",
        "建议尽快更换": "Replace soon",
        "立即更换": "Replace now",
        "偏高": "Elevated",
        "严重": "Critical",
        "宗卷": "Volumes",
        "未检测到宗卷。": "No volumes detected.",
        "网络接口": "Interface",
        "本机 IP": "Local IP",
        "累计接收": "Total received",
        "累计发送": "Total sent",
        "跟随系统语言": "Follow system language",
        "语言": "Language",
        "简体中文": "Simplified Chinese",
        "英语": "English",
        "界面语言": "Interface language",
        "更改系统首选语言后，应用将自动同步。": "The app follows your preferred system language.",
        "查看 MIT 开源许可证": "View MIT license",
        "基于 Better Mac Stats · 原作者 Putu Ari Wisnu 及贡献者": "Based on Better Mac Stats · Putu Ari Wisnu and contributors",
        "退出 MacState 性能监控": "Quit MacState",
        "最高": "max",
    ]
}
func L(_ key: String) -> String { AppLanguage.shared.text(key) }
