//
//  ColorfulBackground.swift
//  RunHaji
//
//  Created by Claude Code on 2025/11/15.
//

import SwiftUI

/// Wrapper for ColorfulX gradient background
/// This view will use ColorfulX once the package is added
/// For now, it falls back to a standard LinearGradient
struct ColorfulBackground: View {
    var body: some View {
        // TODO: Replace with ColorfulX after adding the package
        // File > Add Package Dependencies... > https://github.com/Lakr233/ColorfulX.git
        //
        // Usage with ColorfulX:
        // ColorfulView(color: .constant(ColorfulPreset(
        //     colors: [.accent],
        //     colorSpace: .lab
        // )))
        // .ignoresSafeArea()

        // Fallback gradient for now
        LinearGradient.appGradient
            .opacity(0.1)
            .ignoresSafeArea()
    }
}

#Preview {
    ColorfulBackground()
}
