/statusline

Set up my status line with these exact segments, separated by " | " in dim gray (\033[2;37m):

1. Model name — bold blue (\033[1;34m)
2. Directory (~ for home) in dim white (\033[2;37m), followed by git branch if inside a repo — branch in magenta (\033[35m), with a trailing * if the working tree is dirty. If not in a git repo or branch can't be determined, just show the directory with no branch info (don't show a placeholder).
3. Context window usage as a 10-char block bar [██████░░░░], colored dim green (\033[2;32m) under 50%, dim yellow (\033[2;33m) at 50-79%, dim red (\033[2;31m) at 80%+, followed by dim "ctx:N%".
4. 5-hour rate limit segment, only shown when rate_limits.five_hour data is present in the stdin JSON: "5h:N% ~XhYm" where N is used_percentage and XhYm is time remaining until resets_at (computed as resets_at minus current unix time, hours and minutes). Color: \033[0;33m (non-dim orange/yellow — must be readable, not dim). No 7-day segment, no separate "reset:" label.

Use git --no-optional-locks for branch detection so it never blocks other git operations. Read the script from ~/.claude/statusline-command.sh if it already exists and adapt it; otherwise create it and wire it into settings.json.
