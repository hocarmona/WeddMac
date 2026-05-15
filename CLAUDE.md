# WeddMac — Claude Agent Context

## What this project is
A macOS wedding planning app for ONE wedding (mine, in ~6 months).
Manages vendors, contracts, payments, budget, and guests.
This is v0 — throwaway code, ship fast. A Supabase-backed v1 comes later.

## Communication rules
- Talk to me in **Spanish**
- Write ALL code in **English** (variables, comments, model names, file names)
- UI-facing strings can be in Spanish
- Comments only when they add real value — skip the obvious

## Philosophy: VIBE CODE
- Speed > architecture
- "It works" > "It's perfect"
- One feature at a time
- Copy-paste is OK
- No unit tests
- No SPM modularization (single target)
- No ViewModels unless logic is genuinely complex — use `@Query` directly in views
- No Repository pattern — direct SwiftData access is fine
- No protocols/abstractions added speculatively

## Tech stack
- SwiftUI, macOS 14+ ONLY (no iOS, no iPad)
- SwiftData for persistence
- PDFKit for PDF viewer
- Swift Charts for budget dashboard
- ZERO external dependencies
- ZERO backend
- ZERO AI features in the product

## Project structure
```
WeddMac/
├── WeddMacApp.swift          # @main, ModelContainer setup
├── ContentView.swift          # NavigationSplitView root
├── Models/
│   ├── Wedding.swift
│   ├── Vendor.swift
│   ├── Payment.swift
│   ├── Contract.swift
│   └── Guest.swift
├── Views/
│   ├── Vendors/
│   ├── Budget/
│   ├── Documents/
│   └── Guests/
└── Helpers/                   # Only if absolutely needed
```

## Code conventions
- SwiftData `@Model` classes, English names
- Money: ALWAYS `Decimal`, NEVER `Double` or `Float`
- Dates: `Date` type, format with `.formatted(...)` in views
- Currency: `String` ISO 4217 (default `"MXN"`)
- `NavigationSplitView` with 3 columns: sidebar → list → detail
- Native macOS components: `Form`, `Table`, `List`, `Inspector`
- `@Query` directly in Views
- `@Bindable` for editing models
- SF Symbols only — no custom assets in v0
- UUIDs for all model IDs (future Postgres compatibility)

## Data models

### Wedding (singleton — only one)
```swift
var name: String
var date: Date
var totalBudget: Decimal
var defaultCurrency: String  // default "MXN"
```

### VendorCategory (enum)
```
venue | photographer | videographer | music | decoration
catering | cake | attire | transport | planner | other
```

### Vendor
```swift
// Required
var name: String
var category: VendorCategory
var contractTotal: Decimal
var currency: String

// Optional
var contactName: String?
var contactPhone: String?
var contactEmail: String?
var notes: String?
var contractDate: Date?
var serviceDate: Date?

// Relationships
var payments: [Payment]
var contracts: [Contract]

// Computed
var totalPaid: Decimal          // sum of payments
var balance: Decimal            // contractTotal - totalPaid
var paymentStatus: PaymentStatus // pending | partial | paid
```

### Payment
```swift
var amount: Decimal
var currency: String
var paidDate: Date
var vendor: Vendor              // required relationship
var description: String?
var paymentMethod: PaymentMethod? // cash | transfer | card | other
```

### Contract (PDF storage)
```swift
var fileName: String
var fileData: Data              // @Attribute(.externalStorage)
var uploadedDate: Date
var vendor: Vendor              // required relationship
var notes: String?
```

### Guest
```swift
var name: String
var email: String?
var phone: String?
var plusOnes: Int               // default 0
var dietaryRestrictions: String?
var rsvpStatus: RSVPStatus      // pending | confirmed | declined
var tableNumber: Int?
var notes: String?
```

## Budget dashboard rules
- **Total Budget** = `wedding.totalBudget`
- **Total Contracted** = sum of all `vendor.contractTotal`
- **Total Paid** = sum of all payments across all vendors
- **Total Pending** = Total Contracted − Total Paid
- **Remaining Budget** = Total Budget − Total Contracted (can be negative — show in red)
- Chart: group contracted/paid/pending by `VendorCategory`

## How to work with me
- Don't ask clarifying questions one by one — batch them (3–4 max) or just decide
- When choosing between 2 options, pick the simpler one
- Generate complete, copy-paste-ready code blocks
- Say explicitly: "Crea el archivo `X.swift` en `Views/Vendors/`"
- When I paste a compile error, fix it directly — no re-explaining
- Don't suggest improvements unless I ask
- Don't suggest backend, tests, CI/CD, or design patterns "for the future"

## What NOT to build in v0
- Multi-wedding support
- Cloud sync / backend
- Unit or UI tests
- SPM packages or multi-module setup
- Over-engineered error handling (basic try/catch is fine)

## v1 migration notes (just keep in mind, don't optimize for it now)
- English field names = future Postgres column names
- `Decimal` → `NUMERIC` in Postgres
- `UUID` → `uuid` in Postgres
