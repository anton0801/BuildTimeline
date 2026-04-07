import SwiftUI

// MARK: - Color Palette
extension Color {
    static let btPrimary       = Color(hex: "#F5A623")
    static let btPrimaryDark   = Color(hex: "#E8950D")
    static let btPrimaryLight  = Color(hex: "#FFB940")
    static let btSecondary     = Color(hex: "#1A2B4A")
    static let btSecondaryMid  = Color(hex: "#2D4270")
    static let btAccent        = Color(hex: "#FF6B35")
    static let btSuccess       = Color(hex: "#34C759")
    static let btWarning       = Color(hex: "#FF9500")
    static let btDanger        = Color(hex: "#FF3B30")
    static let btInfo          = Color(hex: "#007AFF")
    static let btTextSecondary = Color(hex: "#6B7280")
    static let btSurface       = Color(.systemBackground)
    static let btGroupedBG     = Color(.systemGroupedBackground)

    // Phase palette
    static let phaseColors: [String: Color] = [
        "foundation": Color(hex: "#8B6914"),
        "walls":      Color(hex: "#5B7FA6"),
        "roof":       Color(hex: "#9B7653"),
        "windows":    Color(hex: "#4FC3F7"),
        "electrical": Color(hex: "#FFD600"),
        "plumbing":   Color(hex: "#4169E1"),
        "finishing":  Color(hex: "#66BB6A"),
    ]

    static func phaseColor(for name: String) -> Color {
        phaseColors[name.lowercased()] ?? .btPrimary
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,1,1,1)
        }
        self.init(.sRGB,
                  red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let btPrimary = LinearGradient(
        colors: [.btPrimary, .btAccent],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let btHero = LinearGradient(
        colors: [Color(hex:"#1A2B4A"), Color(hex:"#2D4270")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let btGold = LinearGradient(
        colors: [Color(hex:"#F5A623"), Color(hex:"#FFD600")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Typography
extension Font {
    static func btLargeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func btTitle()      -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func btTitle2()     -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func btTitle3()     -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func btHeadline()   -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func btBody()       -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func btSubhead()    -> Font { .system(size: 15, weight: .medium, design: .rounded) }
    static func btCaption()    -> Font { .system(size: 12, weight: .regular, design: .rounded) }
    static func btCaption2()   -> Font { .system(size: 11, weight: .medium, design: .rounded) }
}

// MARK: - Phase icon helper
func phaseIcon(for name: String) -> String {
    switch name.lowercased() {
    case "foundation": return "rectangle.fill.on.rectangle.fill"
    case "walls":      return "building.2.fill"
    case "roof":       return "house.fill"
    case "windows":    return "window.casement"
    case "electrical": return "bolt.fill"
    case "plumbing":   return "drop.fill"
    case "finishing":  return "paintbrush.fill"
    default:           return "hammer.fill"
    }
}

func activityIcon(for type: ActivityType) -> String {
    switch type {
    case .projectAdded:  return "folder.badge.plus"
    case .phaseCompleted:return "checkmark.circle.fill"
    case .taskCompleted: return "checkmark.square.fill"
    case .materialAdded: return "shippingbox.fill"
    case .expenseAdded:  return "dollarsign.circle.fill"
    case .photoAdded:    return "photo.fill"
    case .general:       return "bell.fill"
    }
}

func notificationIcon(for type: NotificationType) -> String {
    switch type {
    case .deadline: return "clock.fill"
    case .reminder: return "bell.fill"
    case .budget:   return "dollarsign.circle.fill"
    case .general:  return "info.circle.fill"
    }
}

// MARK: - Date helpers
extension Date {
    var btFormatted: String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: self)
    }
    var btShort: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: self)
    }
    var btTimeAgo: String {
        let sec = Int(Date().timeIntervalSince(self))
        if sec < 60 { return "Just now" }
        if sec < 3600 { return "\(sec/60)m ago" }
        if sec < 86400 { return "\(sec/3600)h ago" }
        return "\(sec/86400)d ago"
    }
}

extension Double {
    func btCurrency(_ symbol: String = "$") -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return symbol + (f.string(from: NSNumber(value: self)) ?? "\(self)")
    }
    func btPercent() -> String { String(format: "%.0f%%", self * 100) }
}

// MARK: - BTButton
struct BTButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isFullWidth: Bool = true
    let action: () -> Void

    enum Style { case primary, secondary, outline, danger, ghost }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                Text(title).font(.btHeadline())
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: style == .outline ? 2 : 0))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder var bg: some View {
        switch style {
        case .primary:   LinearGradient.btPrimary
        case .secondary: Color.btSecondary
        case .outline:   Color.clear
        case .danger:    Color.btDanger
        case .ghost:     Color.btPrimary.opacity(0.12)
        }
    }
    var fg: Color {
        switch style {
        case .primary, .secondary, .danger: return .white
        case .outline: return .btPrimary
        case .ghost:   return .btPrimary
        }
    }
    var border: Color { style == .outline ? .btPrimary : .clear }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - BTTextField
struct BTTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(.btTextSecondary)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
            }
            Group {
                if isSecure { SecureField(placeholder, text: $text) }
                else { TextField(placeholder, text: $text).keyboardType(keyboardType) }
            }
            .font(.btBody())
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - BTCard
struct BTCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - BTProgressBar
struct BTProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var color: Color = .btPrimary

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height/2).fill(Color(.systemGray5)).frame(height: height)
                RoundedRectangle(cornerRadius: height/2)
                    .fill(LinearGradient(colors: [color, color.opacity(0.75)],
                                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(min(max(progress,0),1)), height: height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            }
        }.frame(height: height)
    }
}

// MARK: - Section Header
struct BTSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"

    var body: some View {
        HStack {
            Text(title).font(.btTitle2()).foregroundColor(.primary)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionTitle).font(.btSubhead()).foregroundColor(.btPrimary)
                }
            }
        }
    }
}

// MARK: - Empty State
struct BTEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.btTextSecondary.opacity(0.6))
            Text(title).font(.btTitle3()).foregroundColor(.primary)
            Text(subtitle).font(.btBody()).foregroundColor(.btTextSecondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                BTButton(title: actionTitle, icon: "plus", isFullWidth: false, action: action)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge
struct BTBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.btCaption2())
            .fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - Priority color
extension TaskPriority {
    var color: Color {
        switch self {
        case .low:    return .btSuccess
        case .medium: return .btWarning
        case .high:   return .btDanger
        }
    }
}

// MARK: - EquipmentStatus color
extension EquipmentStatus {
    var color: Color {
        switch self {
        case .available:   return .btSuccess
        case .inUse:       return .btInfo
        case .maintenance: return .btWarning
        }
    }
}
