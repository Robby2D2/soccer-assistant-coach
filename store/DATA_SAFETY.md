Data Safety / Play Console guidance
==================================

This document recommends answers for the Play Console "Data safety" section based on how the app currently works.

Note: Review and adjust these answers to match any analytics or backend services you add.

1) Data collection

- Data collected from users: YES — the app stores user-provided personal data (player names, contact notes) on the device.
- Data shared with third parties: NO by default — the app does not send personal data to remote servers. Data is only shared when the user explicitly exports/shares (CSV or image share). If you integrate cloud backup or analytics later, update this section.

2) Types of data

- Personal info: YES — player and team names, notes entered by the user (stored locally).
- Contacts: NO (the app does not access the user's address book).
- Location: NO.
- Photos / Media: OPTIONAL — the user can attach a photo via the image picker; these are stored locally.
- Files: YES — CSV export files and imports are created and consumed by the user.

3) Purposes

- App functionality: YES — used to provide the app's core functionality (rosters, lineups, exports).
- Analytics: NO (unless you add analytics SDKs).
- Advertising: NO.

4) Security practices

- Data is stored locally on the device; encourage users to secure their device.
- No server-side storage by default.

5) Notes for Play Console

- In the Play Console, mark "Yes" for "Collects personal data" and provide details that data is stored locally and only shared on user action (export/share). Mark "No" for ads and analytics if none are implemented.
