-- Arranges a Finder folder's icon view as a sorted grid, the way Windows Explorer keeps icons tidy.
-- Usage: osascript grid.applescript <folder> <name|kind|modified|grid|none>
on run argv
	set d to (POSIX file (item 1 of argv)) as alias
	set mode to item 2 of argv
	tell application "Finder"
		if (d as text) is (desktop as text) then
			set w to window of desktop
		else
			open d
			set w to container window of d
			set current view of w to icon view
		end if
		set opts to icon view options of w
		if mode is "name" then
			set arrangement of opts to arranged by name
		else if mode is "kind" then
			set arrangement of opts to arranged by kind
		else if mode is "modified" or mode is "dateModified" then
			set arrangement of opts to arranged by modification date
		else if mode is "none" then
			set arrangement of opts to not arranged
		else
			set arrangement of opts to snap to grid
		end if
	end tell
end run
