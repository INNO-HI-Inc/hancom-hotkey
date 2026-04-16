import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject var tabSelection: TabSelection

    var body: some View {
        TabView(selection: $tabSelection.current) {
            GeneralTabView()
                .tabItem { Label("일반", systemImage: "gearshape") }
                .tag(TabSelection.Tab.general)
            ShortcutsTabView()
                .tabItem { Label("단축키", systemImage: "keyboard") }
                .tag(TabSelection.Tab.shortcuts)
            AboutTabView()
                .tabItem { Label("정보", systemImage: "info.circle") }
                .tag(TabSelection.Tab.about)
        }
        .frame(width: 640, height: 500)
        .padding(16)
    }
}
