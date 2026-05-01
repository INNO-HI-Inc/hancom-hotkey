# 📋 벨로그 붙여넣기 가이드

벨로그는 본문 + 메타정보(제목·설명·태그)가 분리된 입력입니다. 아래 두 영역을 **각각** 복사해서 붙여넣으세요.

---

## ① 메타 정보 (벨로그 우측 사이드 / 발행 화면에 입력)

### 제목 (Title 입력란)
```
맥에서 한컴 스타일 단축키 안 먹어서 직접 만든 메뉴바 앱
```

### 한 줄 소개 (발행 → 한 줄 소개) — 150자
```
한컴오피스 Mac판은 스타일 단축키가 사실상 작동하지 않습니다. 그래서 ⌃0~4 누르면 1~5번째 스타일이 바로 적용되는 메뉴바 앱을 만들었어요. Apple 공증 완료 무료 앱, 한글·한셀·한쇼 모두 지원, 자동 업데이트까지. 다운로드는 본문에서.
```

### 시리즈 (선택)
```
한컴단축키 (HancomHotkey)
```

### 태그 (쉼표로 입력)
```
한컴단축키, HancomHotkey, 한컴오피스, HWP, macOS, 메뉴바앱, Swift, 무료앱, 사이드프로젝트, 한컴Mac
```

### 썸네일
- 추천: <https://inno-hi-inc.github.io/hancom-hotkey/og-image.png>
- 또는 메뉴바 드롭다운 캡처

---

## ② 본문 (아래 `===` 사이를 통째로 복사 → 벨로그 마크다운 에디터에 붙여넣기)

===

> Mac에서 한글(HWP) 쓰는 분이라면 알 거예요. 분명 매뉴얼대로 `Ctrl+1`을 눌렀는데 **아무 일도 안 일어나는 그 짜증**. 마우스로 [서식] → [스타일] → 클릭 노가다 다시 시작.
>
> 그래서 만들었습니다. **메뉴바에 상주하면서 `⌃0~4` 한 번에 스타일 적용해주는 무료 앱.**

## TL;DR — 한컴단축키 (HancomHotkey)

🟢 **무엇**: macOS 메뉴바 유틸리티
🟢 **무엇을 해결**: 한컴 Mac판의 작동 안 하는 스타일 단축키
🟢 **어떻게 쓰나**: 한글에서 `⌃0` 누르면 1번째 스타일 (보통 바탕글), `⌃1`은 2번째, ..., `⌃4`는 5번째 즉시 적용
🟢 **얼마**: 무료, 오픈소스
🟢 **안전한가**: Apple Developer ID 서명 + 공증 완료, 키로그 안 함, Secure Input 자동 비활성

📥 **지금 받기** → <https://inno-hi-inc.github.io/hancom-hotkey/>

> 📸 **[이미지 1: 메뉴바 아이콘 + 드롭다운 메뉴 캡처]**
> _캡처해서 여기 드래그-드롭_

---

## 써보면 이런 게 좋아요

### 1️⃣ 키 한 번에 스타일 적용 — 마우스 안 움직여도 됨

가장 큰 차이. 200문단짜리 논문에서 챕터별로 스타일 바꿀 때 차이가 극명합니다.

| | 한컴 기본 | 한컴단축키 |
| --- | --- | --- |
| 동작 | 마우스 → [서식] → [스타일] → 클릭 | `⌃ + 0` |
| 시간 | 약 3초 | 0.1초 |
| 연속 적용 | 매번 마우스 이동 | 키 연타 |

### 2️⃣ `⌃0` 이 1번째 슬롯 (= 보통 바탕글) — 0-인덱스 직관적

한컴 기본은 `⌃1`부터 시작이라 헷갈렸어요. 본 앱은 **`⌃0` = 1번째 슬롯**으로 시프트해서, 가장 많이 쓰는 바탕글을 첫 번째 키에 배치.

```
⌃ 0  →  1번째 슬롯 (보통 바탕글)
⌃ 1  →  2번째 슬롯
⌃ 2  →  3번째 슬롯
⌃ 3  →  4번째 슬롯
⌃ 4  →  5번째 슬롯
```

### 3️⃣ 한글·한셀·한쇼 모두 지원

번들 ID로 자동 감지. 한컴 오피스 어떤 앱을 켜든 똑같이 작동.

### 4️⃣ 다른 앱에선 원래 단축키 그대로

Safari에서 `⌃0` 누르면 → 그냥 통과. Slack, Xcode, Chrome도 마찬가지. **한컴 활성 창일 때만** 동작합니다.

### 5️⃣ 안전 설계

- **암호 입력창(Secure Input) 자동 감지** → 그 순간 키 변환 OFF (은행·1Password 안전)
- **키로그 안 함** — 이벤트 변환만 하고 메모리에서 폐기
- **Apple Developer ID 서명 + 공증 완료** → Gatekeeper 경고 없이 설치
- **오픈소스** → [GitHub](https://github.com/INNO-HI-Inc/hancom-hotkey)에서 코드 직접 검증 가능

### 6️⃣ Sparkle 자동 업데이트

새 버전이 나오면 24시간 이내 메뉴바에서 알림. 클릭 한 번으로 업데이트.

### 7️⃣ 슬립·웨이크 자동 복구

맥북 덮었다 열면 키 후킹이 좀비가 되는 게 macOS의 고질병인데, `NSWorkspace.didWakeNotification` 받아서 자동 재활성화.

### 8️⃣ Universal Binary — Apple Silicon + Intel 모두 네이티브

M1, M2, M3, M4 그리고 Intel 맥까지 한 바이너리로. macOS 13 Ventura 이상.

---

## 다운로드 / 설치 (1분이면 끝)

📥 **다운로드**: <https://inno-hi-inc.github.io/hancom-hotkey/>

설치 절차:

1. 위 링크에서 **DMG 다운로드** 버튼 클릭
2. DMG 더블클릭 → `한컴단축키.app`을 `Applications`로 드래그
3. Launchpad에서 한컴단축키 실행
4. 첫 실행 시 **접근성 권한** 부여 (안내 화면이 시스템 설정 자동으로 열어줌)
5. 한글·한셀·한쇼에서 `⌃ 0~4` 눌러보면 끝

> 📸 **[이미지 2: 홈페이지 hero 영역 캡처]**
> _캡처해서 여기 드래그-드롭_

---

## 그런데 왜 한컴 Mac판은 단축키가 안 먹을까

뜻밖의 진실인데, 한컴 공식 도움말에는 이렇게 적혀 있어요.

```
스타일 적용  Mac 한/글 단축키: ⌃+1, 2…0
```

다 정상이라는데 왜 내 컴퓨터에선 안 먹지?

**한컴은 "스타일 목록의 N번째 자리"에 자동으로 `⌃+N`을 붙이는 구조** 거든요. 즉, `⌃+2`를 눌러도 스타일 목록 2번째 자리에 의미있는 스타일이 없으면 무반응. 새 문서·기본 템플릿에서 그 자리는 거의 비어있고요.

알고 나면 별거 아닌데, 한컴은 이걸 어디에도 강조 안 해놨습니다. 그래서 **한컴단축키는 앱 안에 5단계 가이드를 내장**해서 "스타일 자리 어떻게 옮기는지" 까지 손잡고 알려줍니다.

> 📸 **[이미지 3: 설정 창 - 단축키 탭, 매핑 표 + 5단계 가이드]**
> _캡처해서 여기 드래그-드롭_

---

## 그리고 한 가지 더 — 한컴이 안 알려주는 동작

테스트 중에 발견한 한컴 자체의 미친 동작 하나.

> **`⌃0` 한 번 누르면 정렬·여백만 바뀌고, 두 번 눌러야 글씨체까지 바뀐다**

처음엔 우리 앱 버그인 줄 알고 코드 다 뒤졌는데, [한컴 공식 도움말](https://help.hancom.com/hoffice/multi/ko_kr/hwp/format/style/style(apply).htm)에 답이 있더라고요.

> "새로운 스타일 내용대로 바꾸되, 사용자가 별도로 바꾼 글자 모양은 보호해 그대로 둡니다. 같은 문단에 다시 한 번 같은 스타일을 적용하면 사용자가 직접 바꾼 모양들까지 모두 새로운 스타일 내용대로 덮어 씁니다."

**의도된 동작이었어요.** 좋은 의도지만 사용자 입장에선 짜증. 그래서 **앱 사이트 FAQ에도 명시**해뒀습니다 — "이거 우리 앱 버그 아니에요"라고요.

---

## 기술 스택 (개발자 분들을 위해)

| 영역 | 도구 |
| --- | --- |
| 앱 본체 | Swift, AppKit, SwiftUI |
| 키 후킹 | **CGEventTap** (Quartz.CoreGraphics) |
| 메뉴바 | NSStatusItem + LSUIElement |
| 영속화 | UserDefaults + Codable |
| 자동 실행 | SMAppService |
| 자동 업데이트 | **Sparkle 2.7.2** (EdDSA 서명) |
| 프로젝트 생성 | xcodegen |
| 패키징 | create-dmg, codesign, notarytool |
| 사이트 | 정적 HTML, GitHub Pages |

핵심은 **CGEventTap** 하나입니다. 코드 일부:

```swift
guard let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: KeyRemapper.eventCallback,
    userInfo: Unmanaged.passUnretained(self).toOpaque()
) else {
    return false
}
```

```swift
fileprivate func process(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    // Secure Input(암호 입력) 감지 시 즉시 통과
    if IsSecureEventInputEnabled() {
        return Unmanaged.passUnretained(event)
    }

    let bundleID = activeApp.currentBundleID ?? ""
    guard let rule = cachedRules.first(where: { rule in
        rule.targets(bundleID: bundleID) && rule.matches(keycode: keycode, flags: flags)
    }) else {
        return Unmanaged.passUnretained(event)
    }

    // keycode + flags in-place 수정
    event.setIntegerValueField(.keyboardEventKeycode, value: Int64(rule.toKeycode))
    event.flags = newFlags(from: flags, rule: rule)

    return Unmanaged.passUnretained(event)
}
```

전체 코드: <https://github.com/INNO-HI-Inc/hancom-hotkey>

---

## 사이트도 만들었어요

GitHub Pages 정적 사이트인데도 다음을 다 챙겼습니다.

- **한국어 + 영어 페이지** + `hreflang` 태그
- **og:image 1200×630** 카톡/슬랙 공유 시 썸네일
- **schema.org SoftwareApplication JSON-LD**
- robots.txt + sitemap.xml
- **모바일 sticky 다운로드 CTA**
- FAQ 8개 (트러블슈팅 포함)
- 접근성: skip link, ARIA, focus-visible 링
- changelog.html, privacy.html

🌐 <https://inno-hi-inc.github.io/hancom-hotkey/> (한국어)
🌐 <https://inno-hi-inc.github.io/hancom-hotkey/en/> (English)

---

## 릴리즈는 한 줄로 끝

```bash
./scripts/release.sh 0.6.0
```

이거 한 줄이면 `xcodebuild archive` → 공증 → `create-dmg` → DMG 공증 → Sparkle EdDSA 서명 → `appcast.xml` 자동 갱신 → `HancomHotkey-latest.dmg` 미러까지 **15단계가 자동**.

핵심 트릭은 매 릴리즈에 `HancomHotkey-latest.dmg` 라는 별칭 DMG를 함께 업로드하는 거예요. 홈페이지 다운로드 버튼이 `releases/latest/download/HancomHotkey-latest.dmg` 를 가리키면 **새 버전 낼 때마다 홈페이지 안 고쳐도 자동으로 최신 DMG**.

> 📸 **[이미지 4: 터미널 release.sh 출력]**
> _캡처해서 여기 드래그-드롭_

---

## 만들면서 6번 갈아엎음 (요약)

| 버전 | 한 줄 |
| --- | --- |
| v0.1 | 첫 동작본 |
| v0.2 | 커스텀 매핑 UI 추가 (곧 후회) |
| v0.3 | **커스텀 매핑 UI 통째로 제거** — 한컴이 위치 기반이라 사용자 매핑은 혼란만 야기 |
| v0.4 | Sparkle 자동 업데이트, 한셀·한쇼 지원, 랜딩 페이지 |
| v0.5 | 매핑 시프트 (⌃0이 1번째 슬롯부터 시작) |
| v0.6 | 트리거 키 ⌘ → ⌃ 통일 (한컴 네이티브와 동일 시리즈) |

**가장 큰 깨달음은 v0.3.0에서 기능을 빼는 결정.** 자유도 높은 매핑 편집 UI를 통째로 제거하고 고정 매핑 + HWP 안에서 위치 옮기는 가이드로 대체. 코드 -300줄, 사용자 만족도 ↑.

> 사이드 프로젝트 시작하시는 분, 이 한 가지만 기억하세요: **사용자는 자유도가 아니라 옳은 디폴트를 원한다.**

---

## 한 번 써보세요

📥 **다운로드**: <https://inno-hi-inc.github.io/hancom-hotkey/>
💻 **소스**: <https://github.com/INNO-HI-Inc/hancom-hotkey>
🐛 **버그 / 요청**: <https://github.com/INNO-HI-Inc/hancom-hotkey/issues>

설치하고 한글 켠 다음 `⌃ + 0` 한 번 눌러보시면 — "아 이렇게 살 수 있는 거였구나" 느끼실 거예요.

> Mac으로 한컴 쓰시는 분, GitHub 별 한 번 ⭐ 눌러주시면 다음 사이드 프로젝트 동력으로 씁니다. 댓글로 사용 후기·버그 제보 환영해요.

---

## 참고 자료

- [한컴 공식 — 스타일 적용하기](https://help.hancom.com/hoffice/multi/ko_kr/hwp/format/style/style(apply).htm)
- [한컴 공식 — Mac용 한글 단축키 일람](http://help.hancom.com/hoffice_mac/ko_kr/hwp/view/toolbar/shortcut(table).htm)
- [Sparkle 공식](https://sparkle-project.org)
- [CGEventTap reference](https://developer.apple.com/documentation/coregraphics/cgeventtap)

===

---

# 📌 붙여넣기 체크리스트

1. ☐ 벨로그 글쓰기 클릭 → **마크다운 모드** 확인 (우측 상단 토글)
2. ☐ 위 `===` 사이의 **본문**을 복사해서 에디터에 붙여넣기
3. ☐ 이미지 4개 캡처해서 `📸 [이미지 N: ...]` 표시 자리에 드래그-드롭
4. ☐ 발행 버튼 클릭 → **한 줄 소개 / 시리즈 / 태그** 입력 (위 ① 영역에서 복사)
5. ☐ **썸네일** 업로드 (`og-image.png` 또는 메뉴바 캡처)
6. ☐ URL 슬러그 영문 추천:
   ```
   hancom-mac-shortcut-app
   ```
7. ☐ 발행 → SNS 공유

---

# 🎯 노출 늘리는 팁

- **발행 후 3시간 내에 본인 SNS 공유** (트렌딩 알고리즘이 초기 트래픽 가중치 높음)
- **OKKY / 클리앙 / 디스콰이엇 / 긱뉴스** 등 한국 개발자 커뮤니티에 살짝 자랑글 (자기 홍보 톤은 NO, "이런 문제 있어서 만들어봤어요" 톤)
- 댓글 빠르게 응답 (벨로그 댓글 활성도 = 추천 가중치)
- **시리즈로 묶기** — 다음 글(예: "Sparkle 자동 업데이트 EdDSA 키 관리 썰")로 연결
