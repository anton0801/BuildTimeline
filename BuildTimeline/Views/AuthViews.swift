import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var showLogin   = false
    @State private var showSignUp  = false
    @State private var animateIn   = false

    var body: some View {
        ZStack {
            LinearGradient.btHero.ignoresSafeArea()

            // Decorative background shapes
            ZStack {
                Circle()
                    .stroke(Color.btPrimary.opacity(0.12), lineWidth: 60)
                    .frame(width: 420, height: 420)
                    .offset(x: 140, y: -120)
                Circle()
                    .stroke(Color.btAccent.opacity(0.08), lineWidth: 40)
                    .frame(width: 320, height: 320)
                    .offset(x: -110, y: 180)
            }

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.btPrimary)
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.btPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                        Image(systemName: "building.crane.fill")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)

                    VStack(spacing: 10) {
                        Text("Build Timeline")
                            .font(.btLargeTitle())
                            .foregroundColor(.white)

                        Text("Construction management\nmade simple and efficient")
                            .font(.btBody())
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateIn ? 1 : 0)

                    // Feature chips
                    HStack(spacing: 12) {
                        FeatureChip(icon: "checkmark.circle.fill", label: "Phases")
                        FeatureChip(icon: "chart.bar.fill",        label: "Progress")
                        FeatureChip(icon: "dollarsign.circle.fill", label: "Budget")
                    }
                    .opacity(animateIn ? 1 : 0)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 14) {
                    Button(action: { showSignUp = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Create Account")
                                .font(.btHeadline())
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient.btPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.btPrimary.opacity(0.45), radius: 14, x: 0, y: 7)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: { showLogin = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Log In")
                                .font(.btHeadline())
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Text("By continuing you agree to our Terms & Privacy Policy")
                        .font(.btCaption())
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .offset(y: animateIn ? 0 : 60)
                .opacity(animateIn ? 1 : 0)

                Spacer(minLength: 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8).delay(0.15)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showSignUp)  { SignUpView() }
        .sheet(isPresented: $showLogin)   { LoginView() }
    }
}

struct FeatureChip: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11))
            Text(label).font(.btCaption2())
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .foregroundColor(.white.opacity(0.85))
        .cornerRadius(20)
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var error    = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(LinearGradient.btPrimary).frame(width: 72, height: 72)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 30)).foregroundColor(.white)
                        }
                        Text("Create Account").font(.btTitle()).foregroundColor(.primary)
                        Text("Join Build Timeline and start planning")
                            .font(.btSubhead()).foregroundColor(.btTextSecondary)
                    }
                    .padding(.top, 24)

                    // Fields
                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Full Name", text: $name,
                                    icon: "person.fill")
                        BTTextField(placeholder: "Email Address", text: $email,
                                    icon: "envelope.fill", keyboardType: .emailAddress)
                        BTTextField(placeholder: "Password (min 6 chars)", text: $password,
                                    icon: "lock.fill", isSecure: true)
                        BTTextField(placeholder: "Confirm Password", text: $confirm,
                                    icon: "lock.shield.fill", isSecure: true)
                    }

                    // Error
                    if !error.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.btDanger)
                            Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                        }
                        .padding(12).background(Color.btDanger.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Sign Up button
                    BTButton(title: isLoading ? "Creating..." : "Create Account",
                             icon: "arrow.right.circle.fill") {
                        signUp()
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?").font(.btSubhead()).foregroundColor(.btTextSecondary)
                        Button("Log In") { dismiss.wrappedValue.dismiss() }
                            .font(.btSubhead()).foregroundColor(.btPrimary)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.btPrimary)
                }
            }
        }
    }

    private func signUp() {
        error = ""
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { error = "Please enter your name."; return }
        guard email.contains("@") && email.contains(".") else { error = "Enter a valid email address."; return }
        guard password.count >= 6 else { error = "Password must be at least 6 characters."; return }
        guard password == confirm else { error = "Passwords do not match."; return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let success = appState.signUp(name: name.trimmingCharacters(in: .whitespaces),
                                          email: email.lowercased(),
                                          password: password)
            isLoading = false
            if !success { error = "Could not create account. Please try again." }
            else { dismiss.wrappedValue.dismiss() }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var email    = ""
    @State private var password = ""
    @State private var error    = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(LinearGradient.btHero).frame(width: 72, height: 72)
                            Image(systemName: "person.fill.checkmark")
                                .font(.system(size: 28)).foregroundColor(.white)
                        }
                        Text("Welcome Back").font(.btTitle()).foregroundColor(.primary)
                        Text("Sign in to continue building")
                            .font(.btSubhead()).foregroundColor(.btTextSecondary)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Email Address", text: $email,
                                    icon: "envelope.fill", keyboardType: .emailAddress)
                        BTTextField(placeholder: "Password", text: $password,
                                    icon: "lock.fill", isSecure: true)
                    }

                    if !error.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.btDanger)
                            Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                        }
                        .padding(12).background(Color.btDanger.opacity(0.1)).cornerRadius(10)
                    }

                    BTButton(title: isLoading ? "Signing in..." : "Log In",
                             icon: "arrow.right.circle.fill") {
                        login()
                    }

                    HStack(spacing: 4) {
                        Text("Don't have an account?").font(.btSubhead()).foregroundColor(.btTextSecondary)
                        Button("Sign Up") { dismiss.wrappedValue.dismiss() }
                            .font(.btSubhead()).foregroundColor(.btPrimary)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.btPrimary)
                }
            }
        }
    }

    private func login() {
        error = ""
        guard !email.isEmpty else { error = "Enter your email address."; return }
        guard !password.isEmpty else { error = "Enter your password."; return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let ok = appState.login(email: email.lowercased().trimmingCharacters(in: .whitespaces),
                                    password: password)
            isLoading = false
            if !ok { error = "Invalid credentials. Please try again." }
            else { dismiss.wrappedValue.dismiss() }
        }
    }
}
