//
//  TabSelectionView.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import Defaults
import SwiftUI

struct TabModel: Identifiable {
    let label: String
    let icon: String
    let view: NotchViews

    // Stable identity so matchedGeometryEffect keeps working when tabs are toggled.
    var id: NotchViews { view }
}

/// Tabs currently enabled in settings, in display order.
var tabs: [TabModel] {
    var result = [TabModel(label: "Home", icon: "house.fill", view: .home)]
    if Defaults[.boringShelf] {
        result.append(TabModel(label: "Shelf", icon: "tray.fill", view: .shelf))
    }
    if Defaults[.enableFocusTimer] {
        result.append(TabModel(label: "Focus", icon: "timer", view: .focus))
    }
    if Defaults[.enableClipboardHistory] {
        result.append(TabModel(label: "Clipboard", icon: "doc.on.clipboard.fill", view: .clipboard))
    }
    return result
}

struct TabSelectionView: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Default(.boringShelf) private var shelfEnabled
    @Default(.enableFocusTimer) private var focusEnabled
    @Default(.enableClipboardHistory) private var clipboardEnabled
    @Namespace var animation
    var body: some View {
        let visibleTabs = tabs
        HStack(spacing: 0) {
            ForEach(visibleTabs) { tab in
                    TabButton(label: tab.label, icon: tab.icon, selected: coordinator.currentView == tab.view) {
                        withAnimation(.smooth) {
                            coordinator.currentView = tab.view
                        }
                    }
                    .frame(height: 26)
                    .foregroundStyle(tab.view == coordinator.currentView ? .white : .gray)
                    .background {
                        if tab.view == coordinator.currentView {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                        } else {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                                .hidden()
                        }
                    }
            }
        }
        .clipShape(Capsule())
        // If the active tab gets disabled in settings, fall back to Home.
        .onChange(of: visibleTabs.map(\.view)) { _, views in
            if !views.contains(coordinator.currentView) {
                coordinator.currentView = .home
            }
        }
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}
