import SwiftUI
import Combine
import Network

struct SplashView: View {
    
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var craneAngle: Double = -20
    @State private var gearRotation: Double = 0
    @StateObject private var app: BuildTimelineApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var particles: [SplashParticle] = []
    @State private var particleOpacity: Double = 0
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: BuildTimelineApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient.btHero
                    .opacity(bgOpacity)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image("splash_img")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 7)
                        .opacity(0.8)
                }
                .ignoresSafeArea()
                
                // Particles
                ForEach(particles) { p in
                    Circle()
                        .fill(Color.btPrimary.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .offset(x: p.x, y: p.y)
                        .opacity(particleOpacity)
                }
                
                // Grid overlay
                GeometryReader { geo in
                    ZStack {
                        ForEach(0..<6, id: \.self) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 1)
                                .offset(x: CGFloat(i) * geo.size.width / 5 - geo.size.width / 2)
                        }
                        ForEach(0..<10, id: \.self) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.03))
                                .frame(height: 1)
                                .offset(y: CGFloat(i) * geo.size.height / 9 - geo.size.height / 2)
                        }
                    }
                }
                
                NavigationLink(
                    destination: BuildTimelineWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    // Logo
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(LinearGradient.btPrimary, lineWidth: 3)
                            .frame(width: 140, height: 140)
                            .opacity(0.4)
                            .scaleEffect(logoScale)
                        
                        // Background circle
                        Circle()
                            .fill(LinearGradient.btPrimary)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.btPrimary.opacity(0.5), radius: 24, x: 0, y: 12)
                        
                        // Crane icon
                        Image(systemName: "building.crane.fill")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(craneAngle))
                        
                        // Gear detail
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .offset(x: 36, y: 36)
                            .rotationEffect(.degrees(gearRotation))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Text
                    VStack(spacing: 10) {
                        Text("Build Timeline")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                        
                        Text("Plan your construction stages.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                            .opacity(subtitleOpacity)
                    }
                    
                    Spacer()
                    
                    // Bottom loader
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.btPrimary)
                                .frame(width: i == 1 ? 24 : 8, height: 4)
                                .opacity(titleOpacity)
                        }
                    }
                    .padding(.bottom, 48)
                }
            }
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                BuildTimelineNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
            .onAppear {
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
                runSequence()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func runSequence() {
        particles = (0..<35).map { _ in
            SplashParticle(
                x: .random(in: -180...180),
                y: .random(in: -350...350),
                size: .random(in: 3...9),
                opacity: .random(in: 0.08...0.35)
            )
        }
        
        withAnimation(.easeIn(duration: 0.35)) { bgOpacity = 1 }
        
        withAnimation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.25)) {
            logoScale = 1; logoOpacity = 1
        }
        withAnimation(.easeInOut(duration: 0.9).delay(0.5)) { craneAngle = 0 }
        withAnimation(.linear(duration: 1.2).delay(0.6).repeatForever(autoreverses: true)) { gearRotation = 360 }
        withAnimation(.easeIn(duration: 0.35).delay(0.7)) { particleOpacity = 1 }
        withAnimation(.easeIn(duration: 0.4).delay(0.9)) { titleOpacity = 1 }
        withAnimation(.easeIn(duration: 0.4).delay(1.1)) { subtitleOpacity = 1 }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct SplashParticle: Identifiable {
    let id = UUID()
    let x, y, size, opacity: CGFloat
}

struct BuildTimelineNotificationView: View {
    let app: BuildTimelineApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("push_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 5) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("Lalezar-Regular", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("Lalezar-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("push_claim_img")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Text("SKIP")
                    .font(.custom("Lalezar-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
    }
}


struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image("internet_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 7)
                    .opacity(0.8)
                
                Image("internet")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
