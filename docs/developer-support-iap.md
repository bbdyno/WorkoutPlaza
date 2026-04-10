# Developer Support IAP

WorkoutPlaza developer support is implemented as three consumable In-App Purchases.

Official references:
- https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/
- https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information
- https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/
- https://developer.apple.com/app-store/review/guidelines/

## Product list

These product identifiers are already wired in code:

| Product Type | Product ID | Reference Name | EN Display Name | EN Description | KO Display Name | KO Description |
| --- | --- | --- | --- | --- | --- | --- |
| Consumable | `com.workoutplaza.tip.small` | `WorkoutPlaza Tip Small` | `WorkoutPlaza Coffee` | `A small thank-you for independent development.` | `WorkoutPlaza 커피` | `독립 개발을 응원하는 작은 한 잔.` |
| Consumable | `com.workoutplaza.tip.medium` | `WorkoutPlaza Tip Medium` | `WorkoutPlaza Chalk` | `Help fund steady updates and maintenance.` | `WorkoutPlaza 초크` | `꾸준한 업데이트와 유지보수에 힘을 보태주세요.` |
| Consumable | `com.workoutplaza.tip.large` | `WorkoutPlaza Tip Large` | `WorkoutPlaza Laces` | `A generous boost for bigger improvements.` | `WorkoutPlaza 러닝화` | `더 큰 개선을 위한 든든한 응원입니다.` |

Suggested pricing targets:
- Small: roughly entry-tier support
- Medium: roughly mid-tier support
- Large: roughly strong support

This pricing guidance is an inference, not an Apple requirement. Pick the exact App Store price tier in your base storefront.

## Copy-paste checklist for App Store Connect

If this is the first IAP submission for WorkoutPlaza, submit it together with:
- App version: `1.2.0`
- Build: `2026.04.10.1`

Create these three products under `Monetization > In-App Purchases`:

### 1) WorkoutPlaza Coffee

- Type: `Consumable`
- Reference Name: `WorkoutPlaza Tip Small`
- Product ID: `com.workoutplaza.tip.small`
- Cleared for Sale / Availability: choose the countries or regions where the app is sold
- Tax Category: `Match to parent app` unless you have a separate tax reason to change it

Localization:
- English Display Name: `WorkoutPlaza Coffee`
- English Description: `A small thank-you for independent development.`
- Korean Display Name: `WorkoutPlaza 커피`
- Korean Description: `독립 개발을 응원하는 작은 한 잔.`

### 2) WorkoutPlaza Chalk

- Type: `Consumable`
- Reference Name: `WorkoutPlaza Tip Medium`
- Product ID: `com.workoutplaza.tip.medium`
- Cleared for Sale / Availability: choose the countries or regions where the app is sold
- Tax Category: `Match to parent app` unless you have a separate tax reason to change it

Localization:
- English Display Name: `WorkoutPlaza Chalk`
- English Description: `Help fund steady updates and maintenance.`
- Korean Display Name: `WorkoutPlaza 초크`
- Korean Description: `꾸준한 업데이트와 유지보수에 힘을 보태주세요.`

### 3) WorkoutPlaza Laces

- Type: `Consumable`
- Reference Name: `WorkoutPlaza Tip Large`
- Product ID: `com.workoutplaza.tip.large`
- Cleared for Sale / Availability: choose the countries or regions where the app is sold
- Tax Category: `Match to parent app` unless you have a separate tax reason to change it

Localization:
- English Display Name: `WorkoutPlaza Laces`
- English Description: `A generous boost for bigger improvements.`
- Korean Display Name: `WorkoutPlaza 러닝화`
- Korean Description: `더 큰 개선을 위한 든든한 응원입니다.`

## What to add in App Store Connect

For each consumable product add:
- Type: `Consumable`
- Reference Name
- Product ID
- At least one localization
- Display Name
- Description
- Price schedule
- Availability
- Tax category
- Review screenshot
- Review notes

Optional:
- Promotional image if you want to feature the IAP on the product page

Apple notes:
- Display Name must be 2 to 30 characters.
- Description must be 45 characters or fewer.
- Promotional image must be `1024 x 1024`, JPG or PNG.

## Review screenshot guidance

Upload one screenshot per support product that clearly shows:
- `More > Support Options` entry point, or
- the `Developer Support` screen with the relevant tier visible

Practical recommendation:
- Use an actual app screenshot from the support screen instead of a marketing image
- Make sure the screenshot clearly shows that the purchase is a voluntary one-time support option
- This screenshot is for App Review only and is not shown on the App Store

## Availability and pricing notes

- If you want the IAP to go live immediately after approval, choose at least one country or region in availability.
- If you want approval first but do not want it live yet, submit it and choose `Remove from Sale`.
- Price tiers are your decision. Apple requires a price schedule, but not specific tip amounts.

## Review note template

Use something close to this in each support product's review notes:

```text
This product is a voluntary consumable tip for supporting independent development of WorkoutPlaza.
It does not unlock Pro features or premium content.
The support entry point is in More > Support Options.
Pro subscriptions remain separate in More > Pro.
No test account is required.
```

## Submission notes

- If this is the first In-App Purchase for the app, submit the products with a new app version.
- Make sure each IAP reaches `Ready to Submit`.
- If you want the products approved but not visible yet, submit them and leave them removed from sale.

## Code mapping

- Product IDs and support tier ordering: `WorkoutPlaza/Managers/PurchaseManager.swift`
- Support screen: `WorkoutPlaza/Features/Purchase/DeveloperSupportViewController.swift`
- More tab entry point: `WorkoutPlaza/Features/More/MoreViewController.swift`
- Thank-you flow: `WorkoutPlaza/Features/Purchase/TipThankYouViewController.swift`
