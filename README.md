# WorkoutPlaza 
> 나의 운동 기록을, 나만의 카드로.

WorkoutPlaza는 운동 기록을 카드로 만들어 SNS에 공유할 수 있는 앱입니다.
Apple HealthKit 연동으로 운동 데이터를 자동으로 불러오고, 다양한 운동을 세밀하게 기록합니다.
완료한 운동을 자유롭게 디자인한 카드로 만들어 인스타그램, 스토리, 트위터 등 어디서든 공유하세요.

> Turn your workouts into cards. Share them anywhere.

WorkoutPlaza lets you create beautiful, shareable cards from your workout records.
It syncs with Apple HealthKit to automatically import your data and tracks various workouts in detail.
Design your own workout cards and share them on Instagram, Stories, X, or wherever you like.

<img width="17%" alt="Simulator Screenshot - iPhone 14 Plus - 2026-02-11 at 12 17 19" src="https://github.com/user-attachments/assets/58dfbb7a-1b75-4f55-9072-9ef82fde8094" />
<img width="17%" alt="Simulator Screenshot - iPhone 14 Plus - 2026-02-11 at 12 17 10" src="https://github.com/user-attachments/assets/b2aa2185-da35-4d5c-96f4-ee82dc2b44cd" />
<img width="17%" alt="Simulator Screenshot - iPhone 14 Plus - 2026-02-11 at 12 16 59" src="https://github.com/user-attachments/assets/0f5a32d4-db5c-43b2-a326-71d3d5925e90" />
<img width="17%" alt="Simulator Screenshot - iPhone 14 Plus - 2026-02-11 at 12 17 26" src="https://github.com/user-attachments/assets/8cd9057a-0514-4a99-80cd-d188979fb233" />
<img width="17%" alt="Simulator Screenshot - iPhone 14 Plus - 2026-02-11 at 12 30 47" src="https://github.com/user-attachments/assets/cf3dbbb9-317c-4ed3-9076-c7b4d497ff8c" />


---

## 🚀 Getting Started

This project uses [Tuist](https://tuist.io) for project generation and dependency management.

### Prerequisites
- Xcode 16.0 or later
- [Tuist](https://docs.tuist.io/guides/quick-start/install-tuist/) installed

### Installation

```bash
# Install Tuist (if not already installed)
curl -Ls https://install.tuist.io | bash

# Generate project and install dependencies
make install
```

This will run `tuist install` and `tuist generate` to set up the Xcode workspace.

### Available Commands

- `make install` - Install dependencies and generate Xcode project
- `make clean` - Remove generated project files
- `make help` - Show available commands

### Opening in Xcode

1. Open the workspace:
   ```bash
   open WorkoutPlaza.xcworkspace
   ```

2. **Important:** Select the correct scheme and destination
   - **Scheme:** Choose `WorkoutPlaza` (NOT "Generate Project" or "WorkoutPlaza-Workspace")
   - **Destination:** Select an iOS Simulator (e.g., iPhone 17)
   - Avoid using "My Mac (Designed for iPad/iPhone)" as it may cause display issues

3. Press `Cmd+R` to build and run

### Localization

The project supports multiple languages using Tuist-managed string catalogs:
- Korean (ko)
- English (en)

#### Localization Files Structure

```
Resources/
├── ko.lproj/
│   └── Localizable.strings  # 한국어
└── en.lproj/
    └── Localizable.strings  # English
```

#### Using Localized Strings in Code

Tuist automatically generates type-safe string accessors. After running `make install`, use them like this:

```swift
import UIKit

// Common strings
let okButton = WorkoutPlazaStrings.Common.ok         // "확인" / "OK"
let cancelButton = WorkoutPlazaStrings.Common.cancel // "취소" / "Cancel"

// Tab bar strings
let homeTitle = WorkoutPlazaStrings.Tab.home         // "홈" / "Home"

// Workout types
let running = WorkoutPlazaStrings.Workout.running    // "러닝" / "Running"

// Permission messages
let healthPermission = WorkoutPlazaStrings.Permission.Health.share
```

#### Adding New Translations

1. Add the key-value pair to `Resources/ko.lproj/Localizable.strings`:
   ```
   "new.key" = "한국어 값";
   ```

2. Add the same key to `Resources/en.lproj/Localizable.strings`:
   ```
   "new.key" = "English Value";
   ```

3. Run `make install` to regenerate the Swift accessors

4. Use in your code:
   ```swift
   let text = WorkoutPlazaStrings.New.key
   ```

The generated accessor code is available at `Derived/Sources/TuistStrings+WorkoutPlaza.swift`

See `LocalizationExample.swift` for more usage examples.

---

## 💜 Support Me

<div align="left">
  <a href="https://buymeacoffee.com/bbdyno" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45" width="174" />
  </a>
</div>

<br>

<details>
<summary>
  <b>🪙 Crypto Donation (BTC / ETH)</b><br>
  <span style="font-size: 0.8em; color: gray;">Click to see QR Codes & Addresses</span>
</summary>

<br>

<table>
  <tr>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Bitcoin-FF9900?style=for-the-badge&logo=bitcoin&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3" width="120" alt="BTC QR">
      <br><br>
      <a href="bitcoin:bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3"><b>Send BTC ↗</b></a>
    </td>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571" width="120" alt="ETH QR">
      <br><br>
      <a href="ethereum:0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571"><b>Send ETH ↗</b></a>
    </td>
  </tr>
</table>

<blockquote>
<p><b>BTC:</b> <code>bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3</code></p>
<p><b>ETH:</b> <code>0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571</code></p>
</blockquote>

</details>

<br>

> **Thanks for your support!** 🎁
>
> 🇰🇷 커피 한 잔의 후원은 저에게 큰 힘이 됩니다. 감사합니다! <br>
> 🇺🇸 Thanks for the coffee! Your support keeps me going. <br>
> 🇸🇦 شكراً على القهوة! دعمك يعني لي الكثير. <br>
> 🇩🇪 Danke für den Kaffee! Deine Unterstützung motiviert mich. <br>
> 🇫🇷 Merci pour le café ! Votre soutien me motive. <br>
> 🇪🇸 ¡Gracias por el café! Tu apoyo me motiva a seguir. <br>
> 🇯🇵 コーヒーの差し入れ、ありがとうございます！励みになります。 <br>
> 🇨🇳 感谢请我喝杯咖啡！您的支持是我最大的动力。 <br>
> 🇮🇩 Terima kasih traktiran kopinya! Dukunganmu sangat berarti.
