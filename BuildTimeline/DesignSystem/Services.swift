import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UserNotifications
import Supabase
import Combine

protocol StorageService {
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ permission: AppContext.PermissionData)
    func markLaunched()
    func loadState() -> StoredState
}

struct StoredState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
    }
}

final class UserDefaultsStorageService: StorageService {
    private let store = UserDefaults(suiteName: "group.buildtimeline.core")!
    private let cache = UserDefaults.standard
    
    private enum Key {
        static let tracking = "bt_tracking_payload"
        static let navigation = "bt_navigation_payload"
        static let endpoint = "bt_endpoint_target"
        static let mode = "bt_mode_active"
        static let firstLaunch = "bt_first_launch_flag"
        static let permGranted = "bt_perm_granted"
        static let permDenied = "bt_perm_denied"
        static let permDate = "bt_perm_date"
    }
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            store.set(json, forKey: Key.tracking)
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            store.set(encoded, forKey: Key.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        store.set(url, forKey: Key.endpoint)
        cache.set(url, forKey: Key.endpoint)
    }
    
    func saveMode(_ mode: String) {
        store.set(mode, forKey: Key.mode)
    }
    
    func savePermissions(_ permission: AppContext.PermissionData) {
        store.set(permission.isGranted, forKey: Key.permGranted)
        store.set(permission.isDenied, forKey: Key.permDenied)
        if let date = permission.lastAsked {
            store.set(date.timeIntervalSince1970 * 1000, forKey: Key.permDate)
        }
    }
    
    func markLaunched() {
        store.set(true, forKey: Key.firstLaunch)
    }
    
    func loadState() -> StoredState {
        var tracking: [String: String] = [:]
        if let json = store.string(forKey: Key.tracking),
           let dict = fromJSON(json) {
            tracking = dict
        }
        
        var navigation: [String: String] = [:]
        if let encoded = store.string(forKey: Key.navigation),
           let json = decode(encoded),
           let dict = fromJSON(json) {
            navigation = dict
        }
        
        let endpoint = store.string(forKey: Key.endpoint)
        let mode = store.string(forKey: Key.mode)
        let isFirstLaunch = !store.bool(forKey: Key.firstLaunch)
        
        let granted = store.bool(forKey: Key.permGranted)
        let denied = store.bool(forKey: Key.permDenied)
        let ts = store.double(forKey: Key.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return StoredState(
            tracking: tracking,
            navigation: navigation,
            endpoint: endpoint,
            mode: mode,
            isFirstLaunch: isFirstLaunch,
            permission: StoredState.PermissionData(
                isGranted: granted,
                isDenied: denied,
                lastAsked: date
            )
        )
    }
    
    private func toJSON(_ dict: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict.mapValues { $0 as Any }),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict.mapValues { "\($0)" }
    }
    
    private func encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "<")
            .replacingOccurrences(of: "+", with: ">")
    }
    
    private func decode(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "<", with: "=")
            .replacingOccurrences(of: ">", with: "+")
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

// MARK: - Validation Service

protocol ValidationService {
    func validate() async throws -> Bool
}

final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://cbnlpbmxrieorltmblrs.supabase.co")!,
            supabaseKey: "sb_publishable_rikPsVKqq2zdRyxrOEzvzw_K_JWZkWy"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("⏱️ [BuildTimeline] Validation error: \(error)")
            throw error
        }
    }
}

struct ValidationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}

// MARK: - Network Service

protocol NetworkService {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

final class HTTPNetworkService: NetworkService {
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(BuildTimelineConfig.appID)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: BuildTimelineConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.decodingFailed
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchEndpoint(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://builldtimeline.com/config.php") else {
            throw NetworkError.invalidURL
        }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(BuildTimelineConfig.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [28.0, 56.0, 112.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.requestFailed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool, success,
                          let endpoint = json["url"] as? String else {
                        throw NetworkError.decodingFailed
                    }
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(index + 1) * 1_000_000_000))
                    continue
                } else {
                    throw NetworkError.requestFailed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.requestFailed
    }
}

// MARK: - Notification Service

protocol NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func registerForPush()
}

final class SystemNotificationService: NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func registerForPush() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}

struct BuildTimelineConfig {
    static let appID = "6761786789"
    static let devKey = "rzLtB6cSqFtyiAcam9tWr9"
}
