# Humanize Studio ✦

An English/Japanese AI writing assistant for macOS. The repository also includes a simple browser prototype.

## Native Mac app

**Automatic build:** Open [Actions](https://github.com/feilong6969/humanize-studio/actions/workflows/build-macos.yml), choose the latest successful **Build macOS app** workflow, and download its `HumanizeStudio-macOS` artifact. Unzip it, then move the app into Applications.

**Build on your Mac:** Install Xcode Command Line Tools, clone this repository, and run:

```bash
bash build-mac.sh
open dist/HumanizeStudio.app
```

This creates an ad-hoc signed app. Because it is not notarized by Apple, macOS might warn when opening a downloaded build. Only open builds you trust.

**Using AI:** You need your own OpenAI API key with API billing enabled. Enter the key in the app, select **Save key**, paste text, and press **Rewrite with AI**. The key is stored in your macOS Keychain (not the repository). Text is sent to OpenAI only when you click Rewrite; usage may incur API charges. This app uses `gpt-4.1-mini` by default.

Languages: **English and Japanese**. Styles: Natural, Casual, Simple, Professional, Student.

## Browser prototype

Open `index.html` directly; it offers only basic rule-based offline changes. Optional server mode: use Node.js 18+, set `OPENAI_API_KEY` locally and run `node server.js`. Do not commit API keys.

## Important

AI rewritten text should be checked for accuracy. No AI-detector result can be guaranteed. The macOS app must be compiled on macOS; this repository contains a GitHub Actions build workflow, but a successful build has not yet been verified.
