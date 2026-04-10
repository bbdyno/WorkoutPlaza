Create `WorkoutPlaza.storekit` in this folder from Xcode.

Recommended flow:
1. Open `WorkoutPlaza.xcworkspace` after `tuist generate`.
2. Create `File > New > File... > StoreKit Configuration File`.
3. Choose sync with App Store Connect.
4. Save it as `Configs/StoreKit/WorkoutPlaza.storekit`.

Once the file exists, `Projects/App/Project.swift` will attach it to the `WorkoutPlaza` run scheme automatically on the next `tuist generate`.
