import SwiftUI

struct ShortcutsTabView: View {
    @EnvironmentObject var store: KeyMappingStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mappingCard
                guideCard
                Spacer(minLength: 8)
            }
            .padding(16)
        }
    }

    private var mappingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("매핑")
                .font(.headline)

            VStack(spacing: 6) {
                ForEach(store.rules) { rule in
                    HStack {
                        Text(rule.fromDescription)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(width: 60, alignment: .leading)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("HWP 스타일 \(styleIndex(for: rule))번째")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(rule.fromDescription + " (보내는 키: " + rule.toDescription + ")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Text("어떤 스타일이 적용될지는 HWP의 **스타일 목록 순서** 가 결정합니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color.primary.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var guideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("원하는 스타일을 ⌘0~4 에 배치하려면")
                    .font(.headline)
            }

            Text("HWP 안에서 **스타일 목록의 순서**를 바꾸세요. 예를 들어 \"본문 가.\" 를 ⌘0 로 쓰고 싶다면, HWP 스타일 목록의 **2번째** 자리로 옮기면 됩니다.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                step(num: "1", title: "스타일 창 열기",
                     detail: "HWP 상단 메뉴: 서식 → 스타일…\n또는 단축키 F6 (Touch Bar 맥북은 fn + F6)")
                step(num: "2", title: "옮길 스타일 선택",
                     detail: "목록에서 원하는 스타일을 한 번 클릭")
                step(num: "3", title: "위 / 아래 버튼으로 이동",
                     detail: "목록 우측의 ▲ ▼ 버튼, 또는 드래그로 원하는 자리까지 이동")
                step(num: "4", title: "2 ~ 6번째 자리에 배치",
                     detail: "위 매핑표처럼 ⌘0 은 2번째, ⌘1 은 3번째 … 자리를 사용")
                step(num: "5", title: "완료",
                     detail: "창 닫으면 자동 저장. HWP에서 ⌘0~4 눌러 확인")
            }
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func styleIndex(for rule: MappingRule) -> String {
        let keyName = KeyDescriptor.keyName(for: rule.toKeycode)
        return keyName
    }

    private func step(num: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.footnote).bold()
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).bold()
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
