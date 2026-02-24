# Warning: This application is just designed for fun!

---

# Countdown

A death countdown app for entertainment purposes only. This app displays a countdown timer showing years, months, days, hours, minutes, and seconds.

## Features

- Death countdown timer with 6 rows (Year, Month, Day, Hour, Minute, Second)
- Ultra bold countdown numbers for better visibility
- Smart startup: automatically detects existing data and skips welcome screen
- First-time welcome screen with user agreement
- Username and birth date setup
- Black background with red/gray countdown numbers (gray starts from first zero value)
- Hidden developer mode (tap version 3 times + settings title 5 times)
- Search Users feature in developer mode:
  - Infinite scroll lazy loading
  - 200+ common English names
  - Real-time user generation
  - Search functionality with location button to find your username
  - Add random users
  - Edit countdown and save
  - Sync to server simulation

## Important Disclaimer

This app is **JUST FOR FUN** and is purely for entertainment purposes. The countdown displayed is not based on any real data and should not be taken seriously.

## User Agreement

By using this application, you agree to the following terms:

1. This application is for entertainment only.
2. The countdown displayed is not based on any real data.
3. If you change your fate due to this countdown, there may be force majeure factors.
4. This app does not upload any information to the internet, including crash reports.

## Installation

### Requirements
- Android SDK 27 (Android 8.1) or higher
- Target SDK 36

### Build from source
```bash
flutter pub get
flutter build apk --debug
```

## Developer Mode

To enable developer mode:
1. Go to Settings (tap ■■■ ■■■-■■■■ ■ times)
2. Tap on ■■■■■■■ ■ times
3. Tap on title ■ times

In developer mode, you can access "Search Users" feature where you can:
- Browse generated users with infinite scroll
- Search for specific usernames
- Click the location button to quickly find your username in the list
- Add random users
- Edit countdown timers
- Sync user data to your device

---

<!-- AI-MUST-READ:START -->
<details>
<summary><b></b></summary>

## Development Rules

### Countdown Calculation Algorithm

```
Input: username + birthDate + deviceId
     ↓
1. Combine: "username:birthDate:deviceId"
     ↓
2. Hash: 32-bit DJB2 hash
     ↓
3. Age: hash % 40 + 60 → 60-99 years
     ↓
4. Time (from high bits):
   - milliseconds: hash % 1000 → 0-999ms
   - totalSeconds: (hash >> 10) % 86400 → 0-86399 seconds (24h)
   - hours: totalSeconds / 3600 → 0-23
   - minutes: (totalSeconds % 3600) / 60 → 0-59
   - seconds: totalSeconds % 60 → 0-59
     ↓
5. Death Date = birthDate + age years + hours:minutes:seconds.milliseconds
```

### Gray Rule (Turn Gray When)

- YEAR: turns gray if ≤ 0
- MONTH: turns gray if YEAR ≤ 0 AND MONTH ≤ 0
- DAY: turns gray if YEAR ≤ 0 AND MONTH ≤ 0 AND DAY ≤ 0
- HOUR: turns gray if YEAR ≤ 0 AND MONTH ≤ 0 AND DAY ≤ 0 AND HOUR ≤ 0
- MINUTE: turns gray if all above ≤ 0 AND MINUTE ≤ 0
- SECOND: turns gray if all above ≤ 0 AND SECOND ≤ 0

### Negative Handling

- If death date < current time, display all zeros instead of negative numbers

### Developer Mode

- Version tap count: 3
- Title tap count: 5
- Developer name: "Death God"

### Key Constants

- Package: com.death.countdown
- Min age: 60
- Max age: 100
- Search page size: 30 users

</details>
<!-- AI-MUST-READ:END -->

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Developer

- GitHub: [ChidcGithub](https://github.com/ChidcGithub)
