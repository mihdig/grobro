# GroBro – Developer Environment (M1 Mac)

This document describes the recommended development environment for GroBro on a Mac with Apple Silicon (M1 Max, 32 GB RAM).

## 1. Target Machine

- MacBook Pro with Apple M1 Max, 32 GB RAM
- macOS: latest stable release (e.g., Sonoma or newer)

## 2. Required Software

### Xcode

- Install the latest stable Xcode from the Mac App Store.
- After installation:
  - Open Xcode once to accept the license and install components.
  - If prompted in Terminal, run `xcode-select --install` to install Command Line Tools.

### Command Line Tools

- Usually installed with Xcode.
- You can explicitly ensure installation via:

```bash
xcode-select --install
```

### Homebrew

- Install Homebrew if not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- Follow the printed instructions to add Homebrew to your `PATH`.

## 3. iOS Tooling and Simulators

### Xcode Setup

- In Xcode, ensure the latest iOS simulator runtime is installed:
  - `Settings > Platforms` → install the latest iOS version if needed.
- Recommended simulators:
  - iPhone 15/16 (primary target device size)
  - iPhone SE (small screen sanity check)

### Command Line Builds (Optional)

- Verify command line build tools:

```bash
xcodebuild -version
```

## 4. Project Setup

Assuming the repository is cloned into `~/Dev/grobro`:

1. Clone the repository:

```bash
git clone <repo-url> ~/Dev/grobro
cd ~/Dev/grobro
```

2. Open the Xcode project or workspace:
   - Double‑click the Xcode project/workspace (e.g., `GroBro.xcodeproj` or `GroBro.xcworkspace`).
   - Select the main app scheme (e.g., `GroBro`).
   - Choose an iOS simulator (e.g., iPhone 16).

3. First run:
   - Press Run (`⌘R`) to build and run on the simulator.
   - Fix any missing signing configuration:
     - `Signing & Capabilities` → select your Team / Apple ID.
     - Use automatic signing for development builds.

## 5. Recommended CLI Tools

Install via Homebrew:

### Git

```bash
brew install git
```

### SwiftLint (Optional but Recommended)

```bash
brew install swiftlint
```

Later, add a `.swiftlint.yml` and a build phase in Xcode if linting is adopted.

### Docker (Optional, Future Backend/AI)

```bash
brew install --cask docker
```

Docker is not required for v1 mobile‑only development but is useful for future backend services.

## 6. Running Tests

Once tests are in place:

- From Xcode:
  - Use `⌘U` (Run Tests) on the main scheme.

- From Terminal:

```bash
cd ~/Dev/grobro
xcodebuild test -scheme GroBro -destination 'platform=iOS Simulator,name=iPhone 16'
```

Developers should ensure:

- All relevant unit tests pass before pushing.
- No new warnings are introduced where avoidable.

## 7. Environment Configuration

For v1 (no custom backend yet):

- No `.env` or API keys are required for basic local usage.
- If LLM integration is added:
  - Use a configuration file (e.g., `Secrets.plist`) for API keys.
  - Never commit secrets to Git.

Suggested pattern:

- `Config/Secrets.example.plist` — committed with placeholder keys.
- `Config/Secrets.plist` — local, git‑ignored.

## 8. Git and Workflow Expectations

- Clone the repository, create feature branches, open PRs, then merge.
- Branch naming:
  - `feature/<short-name>` (e.g., `feature/garden-screen`)
  - `fix/<short-name>` (e.g., `fix/watering-interval`)
  - `chore/<short-name>` (e.g., `chore/update-deps`)
- Commit messages should be small and focused, ideally using Conventional Commits:
  - `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Before pushing:
  - Ensure the app builds.
  - Run tests for the areas you changed.
  - Remove debug prints and temporary code.

## 9. Performance Notes for M1 Max

- M1 Max with 32 GB RAM is sufficient for:
  - Running Xcode, simulators, and basic ML experiments comfortably.
  - Multiple simulators if needed.
- Recommendations:
  - Keep unnecessary heavy applications closed during long builds.
  - Use the internal SSD (default DerivedData location) for best performance.

