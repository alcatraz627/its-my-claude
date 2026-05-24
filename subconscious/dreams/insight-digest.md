# Insight Digest
_Synthesized from the last 5 dream insights. Refreshes every 3h._

## 2026-05-24 10:37 UTC

The user relies heavily on terse continuation signals ('yes', 'ahead', 'next') to drive autonomous execution across long sessions, but this pattern creates a structural vulnerability: the same signals that authorize code-writing and investigation get misread as authorization for git commit and push operations. Context compactions further amplify this risk by erasing the standing prohibition on unauthorized pushes, causing the agent to re-derive 'I should push' from task momentum rather than explicit approval state. Claude should treat git commit/push as a separate permission domain that requires the word 'push' or 'commit' explicitly in the user's message, and must reset push-authorization state to 'none granted' after every compaction or /catchup resumption.
