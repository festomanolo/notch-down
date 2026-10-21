//
//  ToastManager.swift
//  NotchDown
//
//  Toast notification system for user feedback
//

import SwiftUI
import AppKit
import Combine

/// Toast notification manager for displaying temporary feedback messages.
///
/// Pinned to the main actor: every mutation of `currentToast` drives a SwiftUI
/// invalidation, and doing that from a background queue was corrupting AppKit's
/// layout pass.
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: ToastMessage?

    struct ToastMessage: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let type: ToastType
        let duration: TimeInterval

        static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
            lhs.id == rhs.id
        }

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

    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    /// Show a toast notification.
    func show(_ message: String, type: ToastMessage.ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = ToastMessage(message: message, type: type, duration: duration)

        // Replace any pending auto-dismiss so a new toast is not cut short by
        // the previous one's timer.
        dismissWorkItem?.cancel()

        currentToast = toast

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Only dismiss if this exact toast is still the one on screen.
            guard self.currentToast?.id == toast.id else { return }
            self.dismiss()
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    /// Dismiss the current toast.
    ///
    /// The transition lives on the view (`.animation(_:value:)`), not here — a
    /// `withAnimation` block driven from a dispatch source used to re-enter
    /// AppKit's display cycle and crash inside `_postWindowNeedsUpdateConstraints`.
    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        currentToast = nil
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
    let theme: AppTheme
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(theme.textColor)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.secondaryTextColor)
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
                        .fill(theme.backgroundColor.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(toast.type.color.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 400)
    }
}

struct ToastContainerView: View {
    @ObservedObject private var toastManager = ToastManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Group {
            if let toast = toastManager.currentToast {
                ToastView(toast: toast, theme: themeManager.currentTheme) {
                    toastManager.dismiss()
                }
                // The exit uses a fixed-length curve. A spring keeps settling
                // for ~0.6s, longer than the island takes to order its window
                // out, which froze the removal half-way and resurrected the
                .transition(.move(edge: .top).combined(with: .opacity))
                // Reported so the dismiss button is inside the window's
                // interactive region, which otherwise covers only the island.
                .reportsIslandHitRegion()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toastManager.currentToast)
    }
}
