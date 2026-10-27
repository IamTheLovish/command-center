# Gen 005 self-diagnosis (checkpoint)
- Good: read the evidence (server + client logs, profiler dumps) before guessing; the shadow-pass and border-gate root causes came from data.
- Miss: first tried to push the code to the mirror directly (blocked as exfiltration) - should have designed the GitHub-side copy first.
- Miss: preview_start reused the token-form tab and wiped it; open new tabs with tabs_create when a filled form must stay.
- Miss: a "// comment {" edit swallowed a brace - check_java caught it before push.
- Rejected idea, logged: skipping GameTests for "client-only" PRs - server code and GameTests call into *ClientEvents classes; unsafe.
