const translations = {
  en: {
    nav_features: "Features",
    nav_support: "Support",
    nav_store: "App Store",
    lang_label: "Language",
    hero_badge: "Now on the App Store",
    hero_title_1: "Build Workout Cards",
    hero_title_2: "that feel like your story.",
    hero_sub: "Track climbing and running sessions, design visuals with templates, and share your progress in one clean flow.",
    hero_desc: "Local-first by default. HealthKit sync when you want it.",
    cta_appstore: "Download on App Store",
    cta_github: "View on GitHub",
    cta_support: "Support Development",
    trust_1: "Running + Climbing",
    trust_2: "Template-based Cards",
    trust_3: "On-device Data",
    mock_sub: "Card studio for your workouts",
    mock_stat_1: "Route count",
    mock_stat_2: "Distance",
    mock_stat_3: "Duration",
    features_title: "Everything for card-style workout journaling",
    features_sub: "From tracking to visual composition, built for creators who train.",
    f1_title: "Dual-Sport Tracking",
    f1_desc: "Log running and climbing in one timeline with sport-specific widgets and summaries.",
    f2_title: "Card Builder",
    f2_desc: "Compose distance, pace, routes, map, and notes with drag-and-resize editing.",
    f3_title: "Template Presets",
    f3_desc: "Apply reusable layouts fast and keep your style consistent across every workout.",
    f4_title: "HealthKit Sync",
    f4_desc: "Pull workouts from HealthKit and keep route data connected to your cards.",
    f5_title: "Import & Share",
    f5_desc: "Export workout packages, import shared records, and collaborate with teammates.",
    f6_title: "Privacy by Design",
    f6_desc: "Core data stays on your device. You decide when and how anything is shared.",
    flow_title: "How WorkoutPlaza fits your routine",
    flow_1_title: "Track",
    flow_1_desc: "Record your run or climbing session and sync baseline data from HealthKit.",
    flow_2_title: "Design",
    flow_2_desc: "Build a visual card using widgets, templates, custom backgrounds, and typography.",
    flow_3_title: "Share",
    flow_3_desc: "Save cards, export your workout package, and publish progress where you want.",
    support_title: "Support the developer",
    support_sub: "WorkoutPlaza is developed independently. Support helps keep updates shipping.",
    support_coffee_title: "Buy Me a Coffee",
    support_coffee_btn: "Open Support Page",
    support_crypto_title: "Crypto Donation",
    copy_btn: "Copy",
    copy_done: "Copied to clipboard",
    footer_rights: "© 2026 WorkoutPlaza. All rights reserved.",
    footer_contact: "Contact",
    footer_terms: "Terms",
    footer_privacy: "Privacy"
  },
  ko: {
    nav_features: "주요 기능",
    nav_support: "후원",
    nav_store: "앱스토어",
    lang_label: "언어",
    hero_badge: "App Store 출시",
    hero_title_1: "운동 기록을",
    hero_title_2: "당신만의 카드로 완성하세요.",
    hero_sub: "클라이밍과 러닝 세션을 기록하고, 템플릿 기반 카드로 디자인한 뒤, 한 흐름으로 공유하세요.",
    hero_desc: "기본은 로컬 저장. 필요할 때만 HealthKit 동기화.",
    cta_appstore: "App Store에서 다운로드",
    cta_github: "GitHub 보기",
    cta_support: "개발 후원하기",
    trust_1: "러닝 + 클라이밍",
    trust_2: "템플릿 기반 카드",
    trust_3: "기기 내 데이터 저장",
    mock_sub: "운동을 카드로 만드는 스튜디오",
    mock_stat_1: "루트 개수",
    mock_stat_2: "거리",
    mock_stat_3: "운동 시간",
    features_title: "카드형 운동 저널링에 필요한 기능을 한 곳에",
    features_sub: "기록부터 비주얼 편집까지, 운동하는 크리에이터를 위해 설계했습니다.",
    f1_title: "멀티 종목 기록",
    f1_desc: "러닝과 클라이밍을 하나의 타임라인에서 종목별 위젯과 함께 관리합니다.",
    f2_title: "카드 빌더",
    f2_desc: "거리, 페이스, 루트, 지도, 메모를 드래그/리사이즈로 자유롭게 배치합니다.",
    f3_title: "템플릿 프리셋",
    f3_desc: "재사용 가능한 레이아웃으로 빠르게 카드 스타일을 맞출 수 있습니다.",
    f4_title: "HealthKit 동기화",
    f4_desc: "HealthKit 운동 기록을 가져오고 경로 데이터까지 카드와 연결합니다.",
    f5_title: "가져오기 및 공유",
    f5_desc: "운동 패키지를 내보내고 가져와 팀원과 기록을 주고받을 수 있습니다.",
    f6_title: "프라이버시 중심",
    f6_desc: "핵심 데이터는 기기에 보관됩니다. 공유 시점과 방법은 직접 선택합니다.",
    flow_title: "WorkoutPlaza 사용 흐름",
    flow_1_title: "기록",
    flow_1_desc: "러닝/클라이밍 세션을 저장하고 HealthKit 데이터와 동기화합니다.",
    flow_2_title: "디자인",
    flow_2_desc: "위젯, 템플릿, 배경, 타이포를 조합해 카드를 완성합니다.",
    flow_3_title: "공유",
    flow_3_desc: "카드를 저장하고 워크아웃 패키지를 내보내 원하는 채널로 공유합니다.",
    support_title: "개발자 후원",
    support_sub: "WorkoutPlaza는 1인 개발 프로젝트입니다. 후원이 업데이트 지속에 큰 도움이 됩니다.",
    support_coffee_title: "커피로 후원하기",
    support_coffee_btn: "후원 페이지 열기",
    support_crypto_title: "암호화폐 후원",
    copy_btn: "복사",
    copy_done: "클립보드에 복사되었습니다",
    footer_rights: "© 2026 WorkoutPlaza. All rights reserved.",
    footer_contact: "문의",
    footer_terms: "이용약관",
    footer_privacy: "개인정보처리방침"
  }
};

const langSelect = document.getElementById("langSelect");
const toastEl = document.getElementById("toast");
let currentLang = "en";
let toastTimer = null;

function t(key) {
  return translations[currentLang]?.[key] ?? translations.en[key] ?? key;
}

function applyLanguage(lang) {
  currentLang = translations[lang] ? lang : "en";
  document.documentElement.lang = currentLang;

  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    const value = t(key);
    if (value) {
      el.textContent = value;
    }
  });

  if (langSelect) {
    langSelect.value = currentLang;
  }
  localStorage.setItem("workoutplaza_lang", currentLang);
}

function showToast(message) {
  if (!toastEl) {
    return;
  }

  toastEl.textContent = message;
  toastEl.classList.add("show");

  if (toastTimer) {
    clearTimeout(toastTimer);
  }

  toastTimer = setTimeout(() => {
    toastEl.classList.remove("show");
  }, 1800);
}

async function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
    return;
  }

  const temp = document.createElement("textarea");
  temp.value = text;
  temp.setAttribute("readonly", "");
  temp.style.position = "absolute";
  temp.style.left = "-9999px";
  document.body.appendChild(temp);
  temp.select();
  document.execCommand("copy");
  document.body.removeChild(temp);
}

function setupCopyButtons() {
  document.querySelectorAll(".copy-btn").forEach((button) => {
    button.addEventListener("click", async () => {
      const targetId = button.getAttribute("data-copy-target");
      const target = targetId ? document.getElementById(targetId) : null;
      if (!target) {
        return;
      }

      try {
        await copyText(target.textContent.trim());
        showToast(t("copy_done"));
      } catch (error) {
        showToast("Copy failed");
      }
    });
  });
}

function setupRevealAnimations() {
  const revealTargets = document.querySelectorAll(".reveal");
  if (revealTargets.length === 0) {
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
        }
      });
    },
    { threshold: 0.12 }
  );

  revealTargets.forEach((el) => observer.observe(el));
}

function setupLanguageSelector() {
  if (!langSelect) {
    return;
  }

  langSelect.addEventListener("change", (event) => {
    applyLanguage(event.target.value);
  });

  const saved = localStorage.getItem("workoutplaza_lang");
  const browser = navigator.language?.split("-")[0] ?? "en";
  const initialLang = saved || (translations[browser] ? browser : "en");
  applyLanguage(initialLang);
}

setupLanguageSelector();
setupCopyButtons();
setupRevealAnimations();
