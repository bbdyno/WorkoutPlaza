# WorkoutPlaza — Claude Code 규칙

## 빌드

```bash
make install        # Tuist 프로젝트 생성
xcodebuild build -workspace WorkoutPlaza.xcworkspace -scheme WorkoutPlaza \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- 폰트/에셋/리소스 파일 추가 후 반드시 `make install` 실행
- `Resources/**/*.json`도 번들에 포함됨 (Project.swift)

## 파일 헤더 형식

모든 Swift 파일의 헤더는 아래 형식을 따른다:

```swift
//
//  FileName.swift
//  WorkoutPlaza
//
//  Created by bbdyno on M/DD/YY.
//
```

- 새 파일 생성 시 반드시 이 형식 적용
- 날짜 형식: `M/DD/YY` (예: `1/19/26`, `4/6/26`)
- 기존 파일의 헤더는 수정하지 않음

## 커밋 규칙

- 커밋 메시지에 `Co-Authored-By: Claude` 붙이지 않음
- 작업 단위별로 커밋 분리

## 디자인 시스템

### 컬러
- 항상 다크모드 강제 (`overrideUserInterfaceStyle = .dark`)
- 블랙/화이트 모노크롬 기반, 스포츠 액센트 컬러(Blue/Green)는 데이터 시각화에만 사용
- UI 크롬(버튼, 탭바, 네비바) → `ColorSystem.mainText` / `ColorSystem.background`
- `ColorSystem.swift`가 중앙 컬러 관리

### 폰트
- UI 크롬 → `AppFont` 유틸리티 사용 (Pretendard 본문, Montserrat 숫자)
- 위젯/카드 편집기 → `FontStyleManager` (사용자 선택 폰트)
- `.systemFont` 대신 `AppFont.body()`, `AppFont.stat()` 등 사용

### 아이콘
- Phosphor Icons (MIT) 사용 — `UIImage(named: "icon.xxx")`
- SF Symbol 사용 금지 (기존 코드에 남은 것 제외)
- 새 아이콘 필요 시 Phosphor에서 다운로드 → `Assets.xcassets/Icons/`에 SVG 추가

### 스타일
- 카드 cornerRadius: 20, continuous curve
- 버튼: pill shape cornerRadius 24
- 캔버스: cornerRadius 24, 보더 없음

## 위젯 시스템

- 디스플레이 모드 전환(탭으로 text↔icon) 지원하지 않음
- 각 레이아웃(text/compact/icon)은 별도 위젯으로 카탈로그에 등록
- `Resources/widget_catalog.json`에 JSON으로 위젯 정의
- `WidgetCatalogManager`가 카탈로그 로드 → ToolSheet에 표시

## 포토카드

- 비율: 3:4 고정 (1080×1440 export)
- 비율 전환 UI 없음
- 구버전 비율(1:1, 4:5, 9:16) 자동 마이그레이션

## Pro 기능 게이트

- `PurchaseManager.shared.isEffectivelyPro`로 체크
- GPX 임포트: Pro 전용
- 경로 위젯: GPS 없으면 Free → 구독 유도, Pro → GPX 임포트 유도
- 일부 폰트/말풍선 스타일: Pro 전용
