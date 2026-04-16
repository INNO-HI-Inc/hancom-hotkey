import SwiftUI

struct AboutTabView: View {
    @EnvironmentObject var updaterVM: UpdaterViewModel

    var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 12)

            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            } else {
                Image(systemName: "keyboard")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
            }

            Text("한컴단축키")
                .font(.title)
                .bold()

            Text("버전 \(version)")
                .foregroundStyle(.secondary)

            VStack(alignment: .center, spacing: 4) {
                Text("© 2026 INNO-HI Inc.")
                Text("macOS 에서 한컴 오피스 스타일 단축키를")
                Text("⌘ 기반으로 편하게 사용하세요.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button("업데이트 확인") { updaterVM.checkNow() }
                .controlSize(.regular)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
