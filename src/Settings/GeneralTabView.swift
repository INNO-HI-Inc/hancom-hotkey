import SwiftUI
import ServiceManagement

struct GeneralTabView: View {
    @EnvironmentObject var store: KeyMappingStore
    @EnvironmentObject var permission: PermissionMonitor
    @EnvironmentObject var updaterVM: UpdaterViewModel
    @State private var launchError: String?

    var body: some View {
        Form {
            Section("상태") {
                HStack(spacing: 10) {
                    Image(systemName: permission.isTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permission.isTrusted ? .green : .orange)
                    Text(permission.isTrusted ? "접근성 권한 부여됨" : "접근성 권한 필요")
                    Spacer()
                    if !permission.isTrusted {
                        Button("시스템 설정 열기") {
                            permission.openSystemSettings()
                        }
                    }
                }

                Toggle("한컴단축키 활성화", isOn: $store.isEnabled)
                    .disabled(!permission.isTrusted)

                HStack {
                    Text("빠른 토글 단축키")
                    Spacer()
                    Text("⌃⌥⌘P")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Section("실행") {
                Toggle("로그인 시 자동 실행", isOn: Binding(
                    get: { store.launchAtLogin },
                    set: { newValue in
                        launchError = nil
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            store.launchAtLogin = newValue
                        } catch {
                            launchError = error.localizedDescription
                        }
                    }
                ))
                if let error = launchError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section("업데이트") {
                Toggle("자동으로 업데이트 확인", isOn: $updaterVM.autoCheck)
                HStack {
                    Text("수동 확인")
                    Spacer()
                    Button("지금 확인") { updaterVM.checkNow() }
                }
            }

            Section("문제 해결") {
                HStack {
                    Text("최근 1시간 로그 저장")
                    Spacer()
                    Button("로그 저장…") {
                        LogExporter.presentSaveAndExport(window: NSApp.keyWindow)
                    }
                }
            }

            Section("초기화") {
                HStack {
                    Text("기본 매핑으로 복원")
                    Spacer()
                    Button("기본값으로 초기화") {
                        store.resetToDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}
