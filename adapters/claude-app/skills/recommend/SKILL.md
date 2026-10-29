---
name: recommend
description: Answers "what now" or "what do you need from me" as a call already made, splitting what needs the user from defaults already taken, then the path to the next checkpoint.
---

# Recommend

Answers "what should happen next" in four blocks: the call, the gates only
the user can clear, the defaults applied without asking, and the path to the
next checkpoint. It exists because the user's attention gets spent on
approvals the assistant could have made itself.

## Sort every open item

Run these tests in order and stop at the first that fits.

1. **Waits on other work?** Then it is blocked on that work, not on the user.
2. **Already authorized** by the request, an earlier message or a prior
   ruling? Then do it. Check the ruling's text before asking again.
3. **Settleable by evidence you can gather?** Gather it and decide.
4. **Would the user answer "yes, obviously"?** It is a default. If you can
   predict the answer, asking is seeking permission, not asking a question.
5. **Everything left** needs taste, an authorization or a fact only the user
   holds. That is a gate. There are usually one or two.

A gate must be clearable today. If clearing it needs something that does not
exist yet, it belongs in test 1.

## Output, in this order and nothing else

| Block | Contents |
|---|---|
| The call | One line saying what should happen, then at most three sentences of why. Not options. |
| Gates | Numbered, at most three, each with a drafted answer so the user can reply `1a 2b`, or `ok` to take every draft. One line of context each. |
| Defaults applied, silence means agreement | One line per call you made. Usually the longest block. |
| Next, to the checkpoint | Ordered steps to the next real stopping point, plus what is blocked and on what. |

Omit a block that has nothing real in it. More than three gates means use the
`decision-bundle` skill instead.

When nothing needs the user and nothing is open, say so in one line and stop.
A manufactured gate costs the user the turn this skill exists to save.

## Boundaries

Recommends, never implements. Never lists a gate whose real blocker is
unfinished work. Never asks a question whose answer it has drafted and
believes.
