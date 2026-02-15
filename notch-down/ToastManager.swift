//
//  ToastManager.swift
//  NotchDown
//
//  Toast notification system for user feedback
//

import SwiftUI
import AppKit
import Combine

/// Toast notification manager for displaying temporary feedback messages
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: ToastMessage?
    
    struct ToastMessage: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType
        let duration: TimeInterval
        
        enum ToastType {
            case success
            case error
            case warning
            case info
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .error: return "xmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .info: return "info.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .error: return .red
                case .warning: return .orange
                case .info: return .blue
                }
            }
        }
    }
    
    private init() {}
    
    /// Show a toast notification
    func show(_ message: String, type: ToastMessage.ToastType = .info, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            self.currentToast = ToastMessage(message: message, type: type, duration: duration)
            
            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if self.currentToast?.id == self.currentToast?.id {
                    self.dismiss()
                }
            }
        }
    }
    
    /// Dismiss current toast
    func dismiss() {
        withAnimation {
            currentToast = nil
        }
    }
    
    // Convenience methods
    func success(_ message: String) {
        show(message, type: .success)
    }
    
    func error(_ message: String) {
        show(message, type: .error, duration: 5.0)
    }
    
    func warning(_ message: String) {
        show(message, type: .warning, duration: 4.0)
    }
    
    func info(_ message: String) {
        show(message, type: .info)
    }
}

// MARK: - Toast View Component

struct ToastView: View {
    let toast: ToastManager.ToastMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(toast.type.color.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 400)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Toast Container Overlay

struct ToastContainerView: View {
    @ObservedObject var toastManager = ToastManager.shared
    
    var body: some View {
        VStack {
            if let toast = toastManager.currentToast {
                ToastView(toast: toast) {
                    toastManager.dismiss()
                }
                .padding(.top, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast?.id)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(toastManager.currentToast != nil)
    }
}
