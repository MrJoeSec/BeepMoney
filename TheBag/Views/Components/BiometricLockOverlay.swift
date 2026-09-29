import SwiftUI

public struct BiometricLockOverlay: View {
    @ObservedObject var authService = BiometricAuthService.shared
    
    public var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.linearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.bottom, 8)
                
                VStack(spacing: 8) {
                    Text("TheBag is Locked")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your personal financial data is stored locally and protected by biometric security.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let error = authService.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Button(action: {
                    Task {
                        _ = await authService.authenticate()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.headline)
                        Text("Unlock with \(authService.biometricTypeString)")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(14)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            Task {
                _ = await authService.authenticate()
            }
        }
    }
}
