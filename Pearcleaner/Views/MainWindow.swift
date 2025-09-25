//
//  AppListH.swift
//  Pearcleaner
//
//  Created by Alin Lupascu on 11/5/23.
//

import Foundation
import SwiftUI
import AlinFoundation
import FinderSync

struct MainWindow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locations: Locations
    @EnvironmentObject var fsm: FolderSettingsManager
    @EnvironmentObject var updater: Updater
    @EnvironmentObject var permissionManager: PermissionManager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("settings.general.glass") private var glass: Bool = false
    @AppStorage("settings.general.sidebarWidth") private var sidebarWidth: Double = 265
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true

    @Binding var search: String
    @State private var showSys: Bool = true
    @State private var showUsr: Bool = true
    @State private var showMenu = false
    @State private var isFullscreen = false
    @State private var selectedPage: CurrentPage = .applications

    var body: some View {

        // Main App Window
        ZStack() {

            HStack(alignment: .center, spacing: 0) {

                Group {
                    switch appState.currentPage {
                    case .applications:
                        applicationsView

                    case .orphans:
                        ZombieView(search: $search)

                    case .development:
                        EnvironmentCleanerView()

                    case .lipo:
                        LipoView()

                    case .launchItems:
                        DaemonView()

                    case .package:
                        PackageView()
                    }
                }

            }
        }
        .background(backgroundView(color: ThemeColors.shared(for: colorScheme).primaryBG))
        .frame(minWidth: appState.currentPage == .orphans ? 700 : 900, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullscreen = false
        }
        .toolbar {
            if #available(macOS 26.0, *) {
                ToolbarItemGroup(placement: .navigation) {
                    Menu {
                        ForEach(CurrentPage.allCases, id: \.self) { page in
                            Button {
                                selectedPage = page
                            } label: {
                                HStack {
                                    Image(systemName: page.icon)
                                    Text(page.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedPage.icon)
                        }
                        .tint(ThemeColors.shared(for: colorScheme).accent)
                    }
                    .menuIndicator(.hidden)
                    .onChange(of: selectedPage) { page in
                        withAnimation(.easeInOut(duration: animationEnabled ? 0.3 : 0)) {
                            // Reset appInfo when changing pages
                            if page == .applications {
                                appState.appInfo = .empty
                                appState.currentView = .empty
                            }
                            // Change page
                            appState.currentPage = page

                        }
                    }

                   NoticeView()
                        .environmentObject(updater)
                        .environmentObject(permissionManager)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        ForEach(CurrentPage.allCases, id: \.self) { page in
                            Button {
                                selectedPage = page
                            } label: {
                                HStack {
                                    Image(systemName: page.icon)
                                    Text(page.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedPage.icon)
                        }
                        .tint(ThemeColors.shared(for: colorScheme).accent)
                    }
                    .menuIndicator(.hidden)
                    .onChange(of: selectedPage) { page in
                        withAnimation(.easeInOut(duration: animationEnabled ? 0.3 : 0)) {
                            // Reset appInfo when changing pages
                            if page == .applications {
                                appState.appInfo = .empty
                                appState.currentView = .empty
                            }
                            // Change page
                            appState.currentPage = page

                        }
                    }
                }
            }

        }
    }

    @ViewBuilder
    private var applicationsView: some View {
        HStack(alignment: .center, spacing: 0) {

            // App List
            AppSearchView(glass: glass, search: $search)
                .frame(width: sidebarWidth)
                .transition(.opacity)
                .ifGlassMain()
                .overlay {
                    if colorScheme == .light {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(ThemeColors.shared(for: colorScheme).primaryText.opacity(0.1), lineWidth: 1)
                    }
                    
                }
                .padding(8)
                .ignoresSafeArea(edges: .top)


            SlideableDivider(dimension: $sidebarWidth, color: .clear)
                .zIndex(3)

            // Details View
            HStack(spacing: 0) {
                Group {
                    switch appState.currentView {
                    case .empty:
                        MountedVolumeView()
                            .id(appState.appInfo.id)
                    case .files:
                        FilesView(search: $search)
                            .id(appState.appInfo.id)
                    case .zombie:
                        ZombieView(search: $search)
                            .id(appState.appInfo.id)
                    case .terminal:
                        TerminalSheetView(homebrew: true, caskName: appState.appInfo.cask)
                            .id(appState.appInfo.id)
                    }
                }
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .zIndex(2)
        }
    }

}




struct MountedVolumeView: View {
    @AppStorage("settings.interface.greetingEnabled") private var greetingEnabled: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject var appState: AppState
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true
    @State private var selectedVolumeIndex: Int = 0

    #if DEBUG
    // Debug sliders
    @State private var perspectiveValue: Double = 0.7
    @State private var rotationValue: Double = 35.0
    @State private var spacingValue: Double = 100.0
    @State private var scaleValue: Double = 0.95
    @State private var minOpacity: Double = 0.5
    @State private var opacityFade: Double = 0.5
    @State private var debugMode: Bool = false
    #endif
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack {
//                HStack {
//                    Spacer()
//
//                    if greetingEnabled, let username = NSFullUserName().components(separatedBy: " ").first {
//                        Text("Welcome, \(username)!")
//                            .font(.largeTitle)
//                            .fontWeight(.semibold)
//                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
//                    }
//                }
                Spacer()

                Text("Select an app from the sidebar to begin")
                    .font(.caption)
                    .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
            }
            .onTapGesture(count: 3) {
                // Triple-tap to toggle debug mode
//                debugMode.toggle()
            }
            if !appState.volumeInfos.isEmpty {
                ZStack {
                    ForEach(Array(appState.volumeInfos.enumerated()), id: \.element.id) { index, volume in
                        let offset = index - selectedVolumeIndex
                        
                        // Only show tiles within 1 position of center
                        if abs(offset) <= 1 {
                            let isCenter = offset == 0
                            let scale = isCenter ? 1.0 : scaleValue
                            let opacity = isCenter ? 1.0 : minOpacity
                            let yOffset = Double(offset) * spacingValue
                            
                            // 3D perspective skew - adjustable
                            let perspective = isCenter ? 0.0 : (offset > 0 ? -perspectiveValue : perspectiveValue)
                            let rotationX = isCenter ? 0.0 : (offset > 0 ? rotationValue : rotationValue)
                            
                            VolumeItemView(volume: volume, isCenter: isCenter, onEject: ejectVolume)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .offset(y: yOffset)
                                .rotation3DEffect(
                                    .degrees(rotationX),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: perspective
                                )
                                .shadow(color: isCenter ? .black.opacity(0.3) : .clear, radius: isCenter ? 10 : 0, x: 0, y: isCenter ? 5 : 0)
                                .zIndex(isCenter ? 10 : Double(10 - abs(offset)))
                                .onTapGesture {
                                    withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.6)) {
                                        selectedVolumeIndex = index
                                    }
                                }
                                .animation(animationEnabled ? .spring(response: 0.4, dampingFraction: 0.6) : .linear(duration: 0), value: selectedVolumeIndex)
                        }
                    }
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            
            // Debug controls at bottom (only show if debug mode enabled)
            #if DEBUG
            if debugMode {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        HStack {
                            Text("Perspective:")
                            Slider(value: $perspectiveValue, in: 0.0...1.0, step: 0.1)
                            Text(String(format: "%.1f", perspectiveValue))
                        }
                        HStack {
                            Text("Rotation:")
                            Slider(value: $rotationValue, in: 0.0...45.0, step: 1.0)
                            Text(String(format: "%.0f°", rotationValue))
                        }
                        HStack {
                            Text("Spacing:")
                            Slider(value: $spacingValue, in: 30.0...120.0, step: 5.0)
                            Text(String(format: "%.0f", spacingValue))
                        }
                        HStack {
                            Text("Scale:")
                            Slider(value: $scaleValue, in: 0.3...1.0, step: 0.05)
                            Text(String(format: "%.2f", scaleValue))
                        }
                        HStack {
                            Text("Min Opacity:")
                            Slider(value: $minOpacity, in: 0.1...0.9, step: 0.05)
                            Text(String(format: "%.2f", minOpacity))
                        }
                        Button("Toggle Debug") {
                            debugMode = false
                        }
                    }
                    .padding()
                    .background(ThemeColors.shared(for: colorScheme).secondaryBG)
                    .cornerRadius(8)
                    .frame(maxWidth: 400)
                }
            }
            #endif
        }
        .padding()
//        .ignoresSafeArea(edges: .top)
        .onAppear {
            // Start with root volume (index 0) selected
            selectedVolumeIndex = 0
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {

            ToolbarItem { Spacer() }

            if #available(macOS 26.0, *) {
                ToolbarItem {
                    if greetingEnabled, let username = NSFullUserName().components(separatedBy: " ").first {
                        Text("Welcome, \(username)!")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem {
                    if greetingEnabled, let username = NSFullUserName().components(separatedBy: " ").first {
                        Text("Welcome, \(username)!")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                }
            }



        }
    }
    
    private func ejectVolume(_ volume: VolumeInfo) {
        let workspace = NSWorkspace.shared
        let success = workspace.unmountAndEjectDevice(atPath: volume.path)
        
        if !success {
            print("Failed to eject volume: \(volume.name)")
        } else {
            // Find the current volume's index before ejection
            if let currentIndex = appState.volumeInfos.firstIndex(where: { $0.id == volume.id }) {
                // Refresh volume list after successful ejection
                appState.loadVolumeInfo()
                
                // Adjust selected index after volume removal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let newCount = appState.volumeInfos.count
                    if newCount > 0 {
                        selectedVolumeIndex = min(currentIndex, newCount - 1)
                    }
                }
            }
        }
    }
}

struct VolumeItemView: View {
    let volume: VolumeInfo
    let isCenter: Bool
    let onEject: (VolumeInfo) -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true
    @State private var purgeableSize: Int64 = 0
    @State private var usedSize: Int64 = 0
    @State private var hoverAvailable: Bool = false
    @State private var hoverPurgeable: Bool = false
    @State private var hoverUsed: Bool = false
    @State private var isHovered: Bool = false
    @State private var isHoveredName: Bool = false


    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack(alignment: .center) {
                volume.icon
                    .resizable()
                    .scaledToFit()
                    .frame(height: 70)
                    .offset(y: 4)

                VStack(alignment: .leading) {
                    HStack {
                        HStack(spacing: 8) {
                            Text(volume.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                                .underline(isHoveredName)
                                .onTapGesture {
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.Storage")!)
                                }
                                .onHover(perform: { isHovered in
                                    self.isHoveredName = isHovered
                                })

                            if volume.isExternal {
                                Button(action: {
                                    onEject(volume)
                                }) {
                                    Image(systemName: "eject")
                                        .font(.title3)
                                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        Spacer()

                        let percentUsed = Double(volume.usedSpace) / Double(volume.totalSpace) * 100
                        Text(String(format: "%.0f%% full", percentUsed))
                            .font(.caption)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                            .offset(y: -5)
                    }
                    .padding(.bottom, 4)

                    HStack {
                        Text("Location:")
                            .font(.caption)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        Text("\(volume.path)")
                            .font(.subheadline)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                    }
                    
                    HStack {
                        Text("Available:")
                            .font(.caption)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        Text(ByteCountFormatter.string(fromByteCount: volume.realAvailableSpace, countStyle: .file))
                            .font(.subheadline)
                            .foregroundStyle(hoverAvailable ? Color.green : ThemeColors.shared(for: colorScheme).primaryText)
                            .animation(.easeInOut(duration: 0.2), value: hoverAvailable)
                    }
                    
                    if volume.purgeableSpace > 0 {
                        HStack {
                            Text("Purgeable:")
                                .font(.caption)
                                .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                            Text(ByteCountFormatter.string(fromByteCount: volume.purgeableSpace, countStyle: .file))
                                .font(.subheadline)
                                .foregroundStyle(hoverPurgeable ? ThemeColors.shared(for: colorScheme).accent : ThemeColors.shared(for: colorScheme).primaryText)
                                .animation(.easeInOut(duration: 0.2), value: hoverPurgeable)
                        }
                        .help("Purgeable space refers to the System Data taken up by macOS. This cannot be manually freed and is automatically managed by your system.")
                    }
                }
            }

            HStack(alignment: .center) {
                Text(ByteCountFormatter.string(fromByteCount: volume.usedSpace, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(hoverUsed ? ThemeColors.shared(for: colorScheme).accent : ThemeColors.shared(for: colorScheme).secondaryText)
                    .offset(y: -1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(ThemeColors.shared(for: colorScheme).primaryBG)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(ThemeColors.shared(for: colorScheme).accent)
                            .brightness(-0.3)
                            .saturation(0.5)
                            .padding(3)
                            .frame(width: geo.size.width * CGFloat(purgeableSize) / CGFloat(volume.totalSpace))
                            .animation(animationEnabled && !volume.hasAnimated ? .spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0) : .linear(duration: 0), value: purgeableSize)
                            .help("Purgeable space refers to the System Data taken up by macOS. This cannot be manually freed and is automatically managed by your system.")

                        RoundedRectangle(cornerRadius: 5)
                            .fill(ThemeColors.shared(for: colorScheme).accent)
                            .padding(3)
                            .frame(width: geo.size.width * CGFloat(usedSize) / CGFloat(volume.totalSpace))
                            .animation(animationEnabled && !volume.hasAnimated ? .spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0) : .linear(duration: 0), value: usedSize)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: geo.size.width * CGFloat(volume.usedSpace) / CGFloat(volume.totalSpace), height: 10)
                                .onHover { hovering in
                                    hoverUsed = hovering
                                }
                            
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: geo.size.width * CGFloat(volume.purgeableSpace) / CGFloat(volume.totalSpace), height: 10)
                                .onHover { hovering in
                                    hoverPurgeable = hovering
                                }
                            
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 10)
                                .onHover { hovering in
                                    hoverAvailable = hovering
                                }
                            
                            Spacer()
                        }
                    }
                }

                Text(ByteCountFormatter.string(fromByteCount: volume.totalSpace, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    .offset(y: -1)
            }
            .frame(height: 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.shared(for: colorScheme).secondaryBG)
        )
        .frame(maxWidth: 500)
        .disabled(!isCenter)
        .scaleEffect((!isCenter && isHovered) ? 1.01 : 1.0)
        .onHover { hovering in
            if !isCenter {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .onChange(of: isCenter) { centered in
            if centered {
                // Clear hover state when becoming center
                isHovered = false
            }
        }
        .onAppear {
            if volume.hasAnimated {
                purgeableSize = volume.usedSpace + volume.purgeableSpace
                usedSize = volume.usedSpace
            } else if isCenter {
                startVolumeAnimation()
            } else {
                purgeableSize = 0
                usedSize = 0
            }
        }
        .onChange(of: isCenter) { centered in
            if centered && !volume.hasAnimated {
                startVolumeAnimation()
            } else if !centered {
                purgeableSize = volume.usedSpace + volume.purgeableSpace
                usedSize = volume.usedSpace
            }
        }
    }
    
    private func startVolumeAnimation() {
        purgeableSize = 0
        usedSize = 0
        
        if animationEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.purgeableSize = volume.usedSpace + volume.purgeableSpace
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.usedSize = volume.usedSpace
                self.markVolumeAsAnimated()
            }
        } else {
            self.purgeableSize = volume.usedSpace + volume.purgeableSpace
            self.usedSize = volume.usedSpace
            self.markVolumeAsAnimated()
        }
    }
    
    private func markVolumeAsAnimated() {
        if let index = appState.volumeInfos.firstIndex(where: { $0.id == volume.id }) {
            appState.volumeInfos[index].hasAnimated = true
        }
    }
    
}
