# agent-ready.jq — the ONE definition of "a row an agent may take right now".
# Shared by ward-revive.sh, session-state.sh and goal.sh, so a fix lands once.
#
# A row is agent-ready when it is pending, not blocked or gated, waits on no other
# row, and nothing about it names the owner: no blocked_on text, no owner lane, no
# owner field, and no subject that says owner/parked/gate. The subject test is a
# belt for the data defect gcp-opus found on 2026-08-26: "owner: run the
# provisioner (PARKED BY OWNER)" sat with empty blocked_on and gated=false, and a
# revive offered it to an unattended agent. Task-table's --json is the input.
[ .tasks[]?
  | select(.status == "pending")
  | select((.blocked // false) == false and (.gated // false) == false)
  | select(((.waits_on // []) | length) == 0)
  | select(((.blocked_on // "") | length) == 0)
  | select(((.metadata.lane // "") | ascii_downcase) != "owner")
  | select(((.metadata.owner // "") | ascii_downcase | test("^(owner|user|human)$")) | not)
  | select((.subject // "") | test("(?i)^\\s*(owner|user)\\s*:|\\bparked\\b|\\bowner[- ]gated\\b|\\(owner\\)|needs (the )?owner") | not)
]
