import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permission: PermissionMonitor
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: permission.isTrusted ? "checkmark.seal.fill" : "keyboard.badge.ellipsis")
                .font(.system(size: 72))
                .foregroundStyle(permission.isTrusted ? .green : Color.accentColor)
                .padding(.top, 32)

            Text(permission.isTrusted ? "준비 완료!" : "한컴단축키에 오신 것을 환영합니다")
                .font(.title)
                .bold()

            if permission.isTrusted {
                readyContent
            } else {
                permissionContent
            }

            Spacer()
        }
        .frame(width: 520, height: 560)
        .padding(.horizontal, 32)
    }

    private var permissionContent: some View {
        VStack(spacing: 16) {
            Text("키보드 입력을 HWP 단축키로 변환하려면\n접근성 권한이 필요합니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                stepRow(number: "1", text: "아래 \"시스템 설정 열기\" 버튼을 누르세요.")
                stepRow(number: "2", text: "목록에서 \"한컴단축키\"를 찾아 체크하세요.")
                stepRow(number: "3", text: "여기로 돌아오면 자동으로 다음 단계로 이동합니다.")
            }
            .padding(16)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                permission.openSystemSettings()
            } label: {
                Label("시스템 설정 열기", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("권한 부여 대기 중…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var readyContent: some View {
        VStack(spacing: 16) {
            Text("HWP에서 ⌘0 ~ ⌘4 를 눌러 스타일을 적용해보세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                shortcutRow(key: "⌘ 0", desc: "본문 가.")
                shortcutRow(key: "⌘ 1", desc: "네모 12폰트")
                shortcutRow(key: "⌘ 2", desc: "본문_동그라미")
                shortcutRow(key: "⌘ 3", desc: "본문_삼각화살")
                shortcutRow(key: "⌘ 4", desc: "본문점")
            }
            .padding(16)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onFinish) {
                Text("완료")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.footnote)
                .bold()
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
                .foregroundStyle(.white)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func shortcutRow(key: String, desc: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .bold()
                .frame(width: 60, alignment: .leading)
            Text(desc)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
