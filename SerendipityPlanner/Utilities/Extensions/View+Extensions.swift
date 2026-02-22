import SwiftUI

extension View {
    @ViewBuilder
    func hideFormBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
