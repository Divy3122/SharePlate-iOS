# SharePlate

SharePlate is an iOS application designed to help small food businesses coordinate the rescue of edible surplus food with community organisations before that food becomes waste.

The application supports the full rescue workflow from identifying surplus food through to collection and donation history. It also integrates with iOS system features so that important rescue information is available outside the main application.

## Project Overview

Small cafés, bakeries, restaurants and similar businesses may have edible food remaining near the end of the trading day. Although this food may still be suitable for consumption, organising a donation can require additional time and coordination during an already busy period.

SharePlate provides a structured workflow where a food business can:

- estimate likely surplus food;
- finalise the available food and collection window;
- choose an accurate pickup address;
- make the surplus available for rescue;
- monitor whether the surplus has been claimed; and
- record the completed collection in donation history.

A community organisation can:

- browse currently available surplus;
- view the pickup location before claiming;
- review the food and collection window;
- claim the surplus;
- manage the active pickup;
- open the collection location in Apple Maps; and
- view completed rescue history.

## Domain Context

The project addresses the problem of edible commercial food being discarded because there is only a limited period between identifying surplus and arranging its collection.

The primary stakeholder is the owner or manager of a small independent food business responsible for managing daily stock and deciding what happens to unsold food.

The secondary stakeholder is a community organisation that can collect and redistribute suitable surplus food.

The core domain workflow is:

**Estimate Surplus → Finalise Surplus → Make Available → Community Reviews Location → Claim Surplus → Collect Food → Donation History**

## Architecture

SharePlate uses MVVM with a dedicated Use Case and Repository layer.

The main dependency flow is:

**SwiftUI View → ViewModel → Use Case → Repository Protocol → CoreDataSharePlateRepository → Core Data**

### Presentation Layer

SwiftUI Views are responsible for displaying application state and handling user interaction.

ViewModels manage presentation state and invoke application Use Cases.

Views and ViewModels do not access Core Data directly.

### Use Case Layer

Business operations are represented using dedicated Use Case structs.

Examples include:

- `FinaliseSurplusListingUseCase`
- `ClaimSurplusUseCase`
- `CompleteDonationPickupUseCase`

Use Cases enforce domain rules and return domain-specific errors when an operation cannot be completed.

### Repository Layer

Database access is hidden behind repository protocols.

Examples include:

- `SurplusRepository`
- `RescueClaimRepository`
- `DonationRepository`

The production implementation is `CoreDataSharePlateRepository`.

Tests use mock repository implementations rather than the real Core Data stack.

## Persistent Database

SharePlate uses **Core Data** for persistent storage.

The database represents related domain concepts including:

- `FoodBusiness`
- `CommunityOrganisation`
- `SurplusListing`
- `SurplusItem`
- `RescueClaim`
- `DonationPickup`

These relationships model the rescue lifecycle rather than storing unrelated values.

Repository queries use predicates to retrieve information that reflects real application conditions, including available surplus listings, listings belonging to a particular business, claims belonging to a community organisation and completed donation history.

Core Data is the primary source of truth for application data.

An earlier design considered CloudKit because a production version of SharePlate would benefit from remote synchronisation between independent business and community accounts. Core Data was selected for the submitted implementation so the persistent domain model, repository architecture, predicates and complete rescue workflow could be implemented and tested reliably with the available development environment.

Because persistence is accessed through repository protocols, another persistence implementation could be substituted later without changing the View or Use Case layers.

## System Extensions

SharePlate implements two iOS system extensions.

### WidgetKit Widget Extension

The WidgetKit extension provides glanceable rescue information from the Home Screen without requiring the user to open SharePlate.

The widget supports:

- `.systemSmall`
- `.systemMedium`

The widget can display role-specific information such as:

- active surplus listing count;
- claimed listing count;
- active pickup count;
- next relevant rescue or pickup;
- pickup time; and
- pickup address.

The WidgetKit extension does not directly access Core Data.

Instead, the main application uses `SharePlateWidgetSyncService` to build a lightweight `SharePlateWidgetSnapshot`.

The snapshot is encoded and stored in the shared App Group container.

After relevant application state changes, the main application calls `WidgetCenter` to reload the widget timeline.

This keeps Core Data as the application source of truth while giving the extension only the information required for its UI.

### Notification Content Extension

SharePlate also implements a Notification Content Extension for domain-specific rescue notifications.

The main application uses `SharePlateNotificationService` and `UNUserNotificationCenter` to schedule local notifications.

The notification category identifier is:

```text
SHAREPLATE_RESCUE_UPDATE
```

Notification data can include:

- event type;
- surplus listing title;
- pickup date; and
- pickup address.

The Notification Content Extension provides a customised expanded view when the notification is opened.

The current project uses local notifications rather than a remote push-notification server.

## App Group

The main SharePlate application and WidgetKit extension share the App Group:

```text
group.uts.edu.au.SharePlate
```

The App Group is used only for lightweight widget snapshot data.

It is **not** used as a replacement database.

Core Data remains the primary persistence layer.

## MapKit Integration

SharePlate also uses MapKit to support the pickup workflow.

On the business side, the Finalise Surplus screen provides address autocomplete so an accurate pickup address can be selected before the listing becomes available.

On the community side, the pickup address is displayed on a map before the surplus is claimed. This allows the organisation to decide whether the collection location is practical before committing to the rescue.

After a successful claim, the pickup screen displays the location again and provides an **Open in Maps** action for Apple Maps directions.

The resulting flow is:

**Business selects address → address is persisted → community views location → community claims surplus → collector opens directions**

## Main Screens

SharePlate includes separate business and community workflows.

Important screens include:

- Role Selection
- Business Dashboard
- Estimate Surplus
- Finalise Surplus
- Active Rescue
- Claim Pickup Details
- Donation History
- Available Surplus
- Claim Surplus
- Community Home
- Community Pickup
- Community Rescue History

## Testing

SharePlate includes unit tests covering Use Cases and repository behaviour.

Tests use mock repositories so business rules can be tested independently from Core Data.

Testing covers successful operations, boundary conditions and domain error cases.

The application was also manually tested on a physical iPhone, including:

- Core Data persistence;
- business and community workflows;
- WidgetKit shared-container updates;
- small and medium widgets;
- widget timeline reloading;
- local notifications;
- expanded Notification Content Extension UI;
- MapKit address autocomplete;
- pre-claim pickup maps; and
- Apple Maps directions.

## Setup Instructions

### Requirements

- Xcode with a current iOS SDK
- iPhone Simulator or physical iPhone
- Apple developer signing configuration
- Notification permission for notification testing

### Run the Main Application

1. Clone the repository.
2. Open the SharePlate Xcode project.
3. Select the `SharePlate` scheme.
4. Select an iPhone Simulator or connected physical iPhone.
5. Configure signing using an available development team if required.
6. Build and run the application.
7. Allow notifications when SharePlate requests permission.

### Widget Setup

The following App Group must be enabled for both the main application target and the WidgetKit extension:

```text
group.uts.edu.au.SharePlate
```

To test the widget:

1. Run SharePlate at least once.
2. Create or update rescue data inside the application.
3. Return to the iPhone Home Screen.
4. Add the SharePlate widget.
5. Test both small and medium sizes.

### Notification Content Extension

To test the notification extension:

1. Allow notifications when prompted.
2. Perform an application action that schedules a rescue notification, such as confirming a claim or completing a pickup.
3. Wait for the local notification.
4. Expand the notification to view the custom Notification Content Extension interface.

### MapKit

MapKit address search requires an internet connection for Apple Maps search results.

No Core Location permission is required because SharePlate does not request the user's live GPS location. The application searches for the pickup address selected by the business.

## Git Workflow

Development uses a stable `main` branch and feature branches for major application work.

Major functionality was developed separately before being merged back into `main`, including domain Use Cases, system extensions and MapKit pickup improvements.

Commit messages follow Conventional Commits style, including prefixes such as:

```text
feat:
fix:
docs:
test:
```

The `main` branch is intended to contain only tested, working application code.

## AI-Assisted Development

AI coding assistants, including ChatGPT and Codex, were used during development to assist with Swift implementation, debugging, integration planning and Xcode configuration.

Generated suggestions were reviewed rather than accepted automatically. Changes were evaluated through compilation, unit testing and manual testing on a physical iPhone.

The use of AI tools is also declared in the assessment Reflective Report.

## References and Attribution

Apple platform documentation was consulted during development for technologies including:

- SwiftUI
- Core Data
- WidgetKit
- App Groups
- UserNotifications
- Notification Content Extensions
- MapKit

The application does not depend on third-party application libraries for its primary domain architecture.
