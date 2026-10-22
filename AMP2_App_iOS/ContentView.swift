//
//  ContentView.swift
//  AMP2_App_iOS
//
//  Created by aaron stockdale on 6/18/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("sidebarSide") private var sidebarSide: String = "left"
    @AppStorage("orientationMode") private var orientationMode: OrientationMode = .portrait
    @State private var selectedTab: Int = 0
    @State private var settingsNavigationPath: [SettingsRoute] = []
    @State private var headsetNavigationPath: [SettingsRoute] = []
    @State private var showDisconnectedAlert = false
    @Environment(HeadsetSession.self) private var headsetSession
    
    private var isSidebarOnLeft: Bool { sidebarSide == "left" }
    private let sidebarContentWidth: CGFloat = 68
    private let leftSidebarSafeAreaTrim: CGFloat = 10
    private let tabItemHeight: CGFloat = 68
    private let tabIconSize: CGFloat = 34
    private let bottomTabIconSize: CGFloat = 22
    private let bottomTabBarHeight: CGFloat = 44
    
    private let tabItems: [(title: String, image: String)] = [
        ("Headset", "Headset 35px"),
        ("Teams", "Team 35px"),
        ("Settings", "Settings 35px")
    ]

    var body: some View {
        GeometryReader { outer in
            let landscape = usesLandscapeLayout(for: outer.size)

            // Safe area only. The outer reader reports zero side insets, which
            // let the Dynamic Island cover the sidebar.
            GeometryReader { inner in
                let insets = inner.safeAreaInsets

                // Content keeps one structural position; only the bar moves.
                // A VStack/HStack branch would reset state on every rotation
                // (Gentex lost their place in the pairing flow).
                selectedContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(barEdge(landscape: landscape),
                             barThickness(landscape: landscape, insets: insets))
                    .overlay(alignment: barAlignment(landscape: landscape)) {
                        tabBar(landscape: landscape, insets: insets)
                    }
                    .ignoresSafeArea(edges: barEdge(landscape: landscape))
            }
            .onChange(of: headsetSession.state) { previous, current in
                handleConnectionChange(from: previous, to: current)
            }
            .alert("Headset disconnected", isPresented: $showDisconnectedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(
                    """
                    The link to your headset dropped. The app is looking for \
                    it again and reconnects on its own once the headset is \
                    back in range.
                    """
                )
            }
        }
    }

    // MARK: - Losing the headset

    /// Alerts on an unplanned disconnect and pops headset-only screens.
    /// Disconnecting from the packet console is intentional and skips the alert.
    private func handleConnectionChange(
        from previous: HeadsetConnectionState,
        to current: HeadsetConnectionState
    ) {
        guard previous.isConnected, !current.isConnected else { return }
        guard !headsetSession.isIntentionallyDisconnected else { return }

        settingsNavigationPath.popHeadsetOnlyScreens()
        headsetNavigationPath.popHeadsetOnlyScreens()
        showDisconnectedAlert = true
    }

    private func usesLandscapeLayout(for size: CGSize) -> Bool {
        switch orientationMode {
        case .system: return size.width > size.height
        case .portrait: return false
        case .landscape: return true
        }
    }

    // MARK: - Tab bar placement

    /// An `Edge.Set` so rotation changes a value, not the modifier chain.
    private func barEdge(landscape: Bool) -> Edge.Set {
        guard landscape else { return .bottom }
        return isSidebarOnLeft ? .leading : .trailing
    }

    private func barAlignment(landscape: Bool) -> Alignment {
        guard landscape else { return .bottom }
        return isSidebarOnLeft ? .leading : .trailing
    }

    /// Content inset matching what the bar overlay covers.
    private func barThickness(landscape: Bool, insets: EdgeInsets) -> CGFloat {
        landscape
            ? sidebarContentWidth + sideInset(for: insets)
            : bottomTabBarHeight + max(insets.bottom, 4)
    }

    /// Extra sidebar width, only when the island is on the sidebar's side.
    /// Landscape reports the inset on both edges (62pt each on iPhone 17), so
    /// the inset alone can't tell which side the island is on.
    private func sideInset(for insets: EdgeInsets) -> CGFloat {
        guard let islandIsOnLeadingEdge, islandIsOnLeadingEdge == isSidebarOnLeft else {
            return 0
        }
        let inset = isSidebarOnLeft ? insets.leading : insets.trailing
        return max(inset - leftSidebarSafeAreaTrim, 0)
    }

    /// `nil` in portrait. `.landscapeRight` puts the island on the leading edge
    /// (verified on iPhone 17).
    private var islandIsOnLeadingEdge: Bool? {
        let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .interfaceOrientation
        switch orientation {
        case .landscapeRight: return true
        case .landscapeLeft: return false
        default: return nil
        }
    }

    /// The bar edge facing the content.
    private func dividerAlignment(landscape: Bool) -> Alignment {
        guard landscape else { return .top }
        return isSidebarOnLeft ? .trailing : .leading
    }

    // MARK: - Tab Bar

    /// Stateless, so rebuilding it on rotation is free.
    private func tabBar(landscape: Bool, insets: EdgeInsets) -> some View {
        Group {
            if landscape {
                verticalTabBar(safeInsets: insets)
            } else {
                horizontalTabBar(safeInsets: insets)
            }
        }
        .overlay(alignment: dividerAlignment(landscape: landscape)) {
            Rectangle()
                .fill(Color(.separator))
                .frame(width: landscape ? 1 : nil, height: landscape ? nil : 1)
        }
    }

    private func horizontalTabBar(safeInsets: EdgeInsets) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                horizontalTabButton(at: index)
            }
        }
        .frame(height: bottomTabBarHeight + max(safeInsets.bottom, 4))
        .background(Color(.systemGray6))
    }

    private func horizontalTabButton(at index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(tabItems[index].image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: bottomTabIconSize, height: bottomTabIconSize)

                Text(tabItems[index].title)
                    .font(.ibmPlexSans(size: 12, bold: selectedTab == index))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
            }
            .foregroundColor(selectedTab == index ? .opsCoreRed : .gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func verticalTabBar(safeInsets: EdgeInsets) -> some View {
        // Must match `barThickness`.
        let sideInset = sideInset(for: safeInsets)

        let buttons = VStack(spacing: 0) {
            Spacer(minLength: 0)

            ForEach(0..<tabItems.count, id: \.self) { index in
                verticalTabButton(at: index)
            }

            Spacer(minLength: 0)
        }
        .frame(width: sidebarContentWidth)

        return HStack(spacing: 0) {
            if isSidebarOnLeft {
                Color.clear
                    .frame(width: sideInset)
                buttons
            } else {
                buttons
                Color.clear
                    .frame(width: sideInset)
            }
        }
        .frame(width: sidebarContentWidth + sideInset)
        .background(Color(.systemGray6))
    }
    
    private func verticalTabButton(at index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 8) {
                Image(tabItems[index].image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: tabIconSize, height: tabIconSize)
                
                Text(tabItems[index].title)
                    .font(.ibmPlexSans(size: 16, bold: selectedTab == index))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(selectedTab == index ? .opsCoreRed : .gray)
            .frame(width: sidebarContentWidth, height: tabItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var selectedContentView: some View {
        Group {
            switch selectedTab {
            case 0: headsetTab
            case 1: TeamsView()
            case 2: AppSettingsView(navigationPath: $settingsNavigationPath)
            default: headsetTab
            }
        }
    }

    /// Live controls when connected, connection help otherwise.
    private var headsetTab: some View {
        NavigationStack(path: $headsetNavigationPath) {
            Group {
                if headsetSession.state.isConnected {
                    HeadsetView()
                } else {
                    DisconnectedView()
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appearance: AppearanceSettingsView()
                case .orientation: OrientationSettingsView()
                case .permissions: PermissionsListView()
                case .userManuals: UserManualsView()
                case .regions: RegionsView()
                case .vadThreshold: VADThresholdView()
                case .ltcVolume: LTCVolumeView()
                case .txPower: TxPowerView()
                #if DEBUG
                case .packetConsole: PacketConsoleView()
                #endif
                }
            }
        }
    }
    
}



#Preview {
    let session = HeadsetSession()
    let sync = HeadsetSettingsSync(transport: session)
    ContentView()
        .environment(session)
        .environment(sync)
}
