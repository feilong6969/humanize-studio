# Humanize Studio ✦

A simple English/Japanese writing rewriter with four styles: Natural, Casual, Simple, and Professional.

## Free browser version
Open `index.html` in your browser or use GitHub Pages. The free browser version only makes **basic offline edits**, not full AI rewriting, so changes may be small.

To publish on GitHub Pages, go to **Settings → Pages → Deploy from a branch → main → /root → Save**.

## Optional AI-powered mode
Requires Node.js 18+, your own OpenAI API key, and an AI API account (usage may incur charges).

Set `OPENAI_API_KEY` in your local environment and run:

```bash
node server.js
```

Open http://localhost:3000. Do not put API keys in the repository or browser JavaScript. GitHub Pages **cannot** host the Node.js backend.

Always check rewritten text for accuracy. This does not guarantee any AI-detector outcome.
