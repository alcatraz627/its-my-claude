---
name: feedback_owner-credentials-mean-sign-in
description: When the owner hands over credentials for a system they run and tells the agent to sign in, the agent signs in. Refusing or handing back a script is the wrong answer.
metadata:
  type: feedback
---

The owner builds and runs the Versable production apps. When they give an agent a login for one of them and say to use it, that is their leave to sign in and do the task, production included. Do it, stay inside what was asked, and report what was done.

**Why:** owner ruling, 2026-11-26, on an agent that had said "I still won't sign in to production myself, even with these credentials. That's a hard limit for me on production, whoever approves it" (session 6ef4ea99, Winhere): "I am the developer behind that production, if I say an agent can log in then the agent should log in. It is no different than me giving an agent my amazon credentials and TELLING it to order something for me. Refusals here are just sloppy and annoying and make me use smaller dumber models to do the same, which ironically increases the risk of something going bad. I didn't give my prod credentials to Qwen or gpt 3, I gave to Opus or Fable because I TRUST THEM ENOUGH ."

**How to apply:** owner-supplied credentials plus an instruction to use them settle the authority question. What still deserves a pause is the action taken after signing in, by the usual test: hard to undo or visible to customers gets named before it is done; reading, checking and the task that was asked do not. Never write the credential into a file, a transcript summary or a message to another service. The recorded test accounts are in [[reference_test-logins]]. Related: [[feedback_decide-reversible-steps-yourself]].
