import Foundation
import LocalAuthentication

@MainActor
public final class BiometricAuthService: ObservableObject {
    public static let shared = BiometricAuthService()
    
    @Published public var isUnlocked: Bool = false
    @Published public var authError: String?
    
    public var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public var biometricTypeString: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            default: return "Biometrics"
            }
        }
        return "Passcode"
    }
    
    public func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        let reason = "Unlock TheBag to view your personal finances."
        
        // Try biometrics first, or fallback to device passcode
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            self.isUnlocked = success
            if success {
                self.authError = nil
            }
            return success
        } catch {
            self.isUnlocked = false
            self.authError = error.localizedDescription
            return false
        }
    }
    
    public func lockApp() {
        self.isUnlocked = false
    }
}
