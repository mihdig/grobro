import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Cross-Platform Navigation Modifiers

extension View {
    /// Cross-platform safe navigationBarTitleDisplayMode
    /// On macOS this modifier is not available, so we use conditional compilation
    @ViewBuilder
    public func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Cross-platform safe keyboardType - iOS only
    #if os(iOS)
    @ViewBuilder
    public func emailKeyboard() -> some View {
        self.keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
    }

    @ViewBuilder
    public func decimalKeyboard() -> some View {
        self.keyboardType(.decimalPad)
    }
    #else
    @ViewBuilder
    public func emailKeyboard() -> some View {
        self
    }

    @ViewBuilder
    public func decimalKeyboard() -> some View {
        self
    }
    #endif
}
