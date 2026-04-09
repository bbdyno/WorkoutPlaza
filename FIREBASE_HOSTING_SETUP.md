# Firebase Hosting Setup

WorkoutPlaza 소개 사이트와 `app-ads.txt` 를 무료 `Firebase Hosting` 으로 배포하는 절차.

기준:
- `Firebase Hosting` 사용
- `Firebase App Hosting` 사용 안 함
- 정적 사이트 루트는 `docs/`
- 무료 `Spark` 플랜 기준

## 목표

배포 후 아래 URL이 열려야 한다.

- `https://<project-id>.web.app/`
- `https://<project-id>.web.app/app-ads.txt`
- `https://<project-id>.web.app/privacy.html`
- `https://<project-id>.web.app/terms.html`

## 1. Firebase 프로젝트 생성

1. Firebase Console에서 새 프로젝트 생성
2. Hosting만 사용할 거면 Analytics는 선택 사항
3. 플랜은 `Spark` 로 시작

참고:
- `Firebase Hosting` 은 무료 시작 가능
- `Firebase App Hosting` 은 사용하지 말 것

## 2. CLI 설치

```bash
npm install -g firebase-tools
firebase login
```

로그인 브라우저가 열리면 Google 계정으로 로그인한다.

## 3. 프로젝트 루트에서 초기화

레포 루트에서 실행:

```bash
cd /path/to/WorkoutPlaza
firebase init hosting
```

질문에는 아래처럼 답하면 된다.

- `Use an existing project`: 방금 만든 Firebase 프로젝트 선택
- `What do you want to use as your public directory?`: `docs`
- `Configure as a single-page app (rewrite all urls to /index.html)?`: `No`
- `Set up automatic builds and deploys with GitHub?`: `No`

## 4. 생성돼야 하는 파일

초기화 후 보통 아래 파일이 생긴다.

- `firebase.json`
- `.firebaserc`

`firebase.json` 예시는 아래와 비슷하면 된다.

```json
{
  "hosting": {
    "public": "docs",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```

## 5. 배포

```bash
firebase deploy --only hosting
```

배포가 끝나면 보통 아래 두 URL이 나온다.

- `https://<project-id>.web.app`
- `https://<project-id>.firebaseapp.com`

AdMob/App Store 용도로는 `web.app` 주소를 우선 사용하면 된다.

## 6. 배포 후 확인

반드시 직접 열어서 확인:

```text
https://<project-id>.web.app/app-ads.txt
https://<project-id>.web.app/privacy.html
https://<project-id>.web.app/terms.html
https://<project-id>.web.app/
```

특히 `app-ads.txt` 는 아래 한 줄만 보여야 한다.

```txt
google.com, pub-8965771939775493, DIRECT, f08c47fec0942fa0
```

## 7. App Store Connect 수정

각 앱의 `Marketing URL` 을 아래처럼 변경:

```text
https://<project-id>.web.app/
```

중요:
- `app-ads.txt` 전체 URL을 넣는 게 아님
- 사이트 URL만 넣어야 함
- AdMob는 그 hostname 루트에서 `/app-ads.txt` 를 찾음

## 8. AdMob 반영 대기

- App Store Connect 수정 후 즉시 반영되지 않을 수 있음
- 보통 최소 `24시간` 이상 대기
- AdMob의 `app-ads.txt` 상태가 갱신되는지 확인

## 9. 비용 메모

- 현재 용도에서는 `Spark` 무료 티어로 시작 가능
- 정적 사이트 + `app-ads.txt` + `privacy/terms` 정도면 보통 무료 범위에 머물 가능성이 높음
- 트래픽이 커지면 무료 한도를 넘길 수는 있음

## 10. 나중에 내가 이어서 할 것

배포가 끝나고 아래 값을 받으면 앱 쪽 실제 광고 연결 진행 가능.

- `ADMOB_APP_ID`
- `ADMOB_HOME_BANNER_UNIT_ID`
- `ADMOB_STATISTICS_BANNER_UNIT_ID`
- 최종 `Marketing URL`

