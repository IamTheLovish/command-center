# Gen 006 self-diagnosis (account B, Oct 22 01:14 - 14:20)
- Good: evidence first - server + client logs and profiler dumps found both root causes (border-gated pathfinder,
  shadow pass) before any code. 11 PRs merged, each with a dev-log note; no revert needed so far.
- Good: two CI bugs found by watching our own runs (flake reruns failing the audit; rate-limited mirror reads).
- Miss: pushed code to the mirror directly first (blocked as exfiltration) and then designed a token-based mirror
  that lovish had to set up; the token-free design (public repo reads) was available from the start. Lesson: for
  public repos, read, don't copy.
- Miss: an agent's GameTest asserted vanilla behaviour wrongly (furnaces); CI caught it. Review agent tests' claims
  about vanilla before trusting them.
- Miss: a scratch copy of merge_pr.py lacked known_flakes.txt, so a known flake wasn't rerun. Run repo tools from a
  checkout.
- Miss: the container restart lost an agent's uncommitted work; agents now commit + push WIP each step.
- Usage: 2 opus + 5 sonnet agents; the rest done directly. Effort: high for agents, never max.
