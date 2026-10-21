# Resume Helper server

Lets the Resume Helper chat use Claude. The API key and the system prompt live in this
server only, never in the web app.

## Run it (Windows PowerShell)

    cd "C:\Users\aayus\Desktop\Cursor work\placement app aerostar version"
    # put your key in server.env (ANTHROPIC_API_KEY=...) - or set it just for this terminal:
    # $env:ANTHROPIC_API_KEY = "sk-ant-..."
    node server/resume_helper_server.js

It serves the built app (`build/web`) and `/api/resume-chat` on port 8767.
Open http://localhost:8767/ or, on your phone, http://<your-PC-IP>:8767/ .
Check it with http://localhost:8767/api/health (`keyConfigured` should be true).

Optional env vars: `PORT`, `HOST`, `RESUME_MODEL` (default `claude-sonnet-5-5`).

## Without a key / on GitHub Pages
If `/api/resume-chat` is missing or has no key, the chat silently falls back to the
built-in rule-based helper. Force that with `--dart-define=RESUME_BOT=scripted`.

## Deploying later
`handleChat(body, apiKey)` in `resume_helper_server.js` is a plain JSON-in, JSON-out
function, so it moves into a Cloudflare Worker or Vercel function unchanged. Build the app
with `--dart-define=RESUME_BOT_URL=https://<your-host>/api/resume-chat` to point at it.
Add the real domain to an allow-list and keep the per-IP rate limit when you deploy.

## Privacy note
Each chat sends the student's name, phone, email, college, course and what they type to
Anthropic's API. Mention this in your privacy policy before real students use it.
