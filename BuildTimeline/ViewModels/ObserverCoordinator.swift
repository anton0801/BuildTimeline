import Foundation
import AppsFlyerLib

final class ObserverCoordinator {
    private let observable: Observable
    private let storage: StorageService
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var context: AppContext
    
    init(
        observable: Observable,
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.observable = observable
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
        self.context = AppContext()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        let stored = storage.loadState()
        context.tracking = stored.tracking
        context.navigation = stored.navigation
        context.mode = stored.mode
        context.isFirstLaunch = stored.isFirstLaunch
        context.permission = AppContext.PermissionData(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
        observable.notify(event: .initialized)
    }
    
    // MARK: - Tracking
    
    func handleTracking(_ data: [String: Any]) async {
        let converted = data.mapValues { "\($0)" }
        context.tracking = converted
        storage.saveTracking(converted)
        
        observable.notify(event: .trackingReceived(converted))
        
        // Auto-trigger validation
        await performValidation()
    }
    
    func handleNavigation(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        context.navigation = converted
        storage.saveNavigation(converted)
        
        observable.notify(event: .navigationReceived(converted))
    }
    
    // MARK: - Validation
    
    private func performValidation() async {
        guard context.hasTracking() else {
            observable.notify(event: .validationCompleted(false))
            return
        }
        
        do {
            let isValid = try await validation.validate()
            observable.notify(event: .validationCompleted(isValid))
            
            if isValid {
                // ✅ Validation passed
                await executeBusinessLogic()
            } else {
                // ❌ Validation failed - идём на Main
                observable.notify(event: .navigateToMain)
            }
        } catch {
            print("⏱️ [BuildTimeline] Validation error: \(error)")
            observable.notify(event: .validationCompleted(false))
            observable.notify(event: .navigateToMain)
        }
    }
    
    // MARK: - Business Logic
    
    private func executeBusinessLogic() async {
        guard !context.isLocked, context.hasTracking() else {
            observable.notify(event: .navigateToMain)
            return
        }
        
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            await finalizeWithEndpoint(temp)
            return
        }
        
        // Check organic + first launch
        let attributionProcessed = context.metadata["attribution_processed"] as? Bool ?? false
        if context.isOrganic() && context.isFirstLaunch && !attributionProcessed {
            context.metadata["attribution_processed"] = true
            await executeOrganicFlow()
            return
        }
        
        // Fetch endpoint
        await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !context.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await network.fetchAttribution(deviceID: deviceID)
            
            for (key, value) in context.navigation {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            observable.notify(event: .attributionFetched(fetched))
            
            let converted = fetched.mapValues { "\($0)" }
            context.tracking = converted
            storage.saveTracking(converted)
            
            await fetchEndpoint()
        } catch {
            print("⏱️ [BuildTimeline] Attribution error: \(error)")
            observable.notify(event: .navigateToMain)
        }
    }
    
    private func fetchEndpoint() async {
        guard !context.isLocked else { return }
        
        let trackingDict = context.tracking.mapValues { $0 as Any }
        
        do {
            let url = try await network.fetchEndpoint(tracking: trackingDict)
            observable.notify(event: .endpointFetched(url))
            await finalizeWithEndpoint(url)
        } catch {
            print("⏱️ [BuildTimeline] Endpoint error: \(error)")
            observable.notify(event: .navigateToMain)
        }
    }
    
    private func finalizeWithEndpoint(_ url: String) async {
        context.endpoint = url
        context.mode = "Active"
        context.isFirstLaunch = false
        context.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
        
        if context.permission.canAsk {
            observable.notify(event: .showPermission)
        } else {
            observable.notify(event: .navigateToWeb)
        }
    }
    
    // MARK: - Permission
    
    func requestPermission() async {
        // ✅ Локальная копия для избежания inout capture
        var localPermission = context.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<AppContext.PermissionData, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                }
                
                self.storage.savePermissions(permission)
                continuation.resume(returning: permission)
            }
        }
        
        context.permission = updatedPermission
        observable.notify(event: .permissionGranted)
        observable.notify(event: .navigateToWeb)
    }
    
    func deferPermission() {
        context.permission.lastAsked = Date()
        storage.savePermissions(context.permission)
        
        observable.notify(event: .permissionDeferred)
        observable.notify(event: .navigateToWeb)
    }
    
    // MARK: - Network
    
    func networkStatusChanged(_ isConnected: Bool) {
        if isConnected {
            observable.notify(event: .hideOffline)
        } else {
            observable.notify(event: .showOffline)
        }
    }
    
    // MARK: - Timeout
    
    func timeout() {
        guard !context.isLocked else { return }
        observable.notify(event: .navigateToMain)
    }
}
