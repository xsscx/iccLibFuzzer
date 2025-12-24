# Copilot Session Tracking

This directory maintains state tracking for GitHub Copilot CLI sessions working on the iccLibFuzzer project.

## Directory Structure

```
.copilot-sessions/
├── README.md                          # This file
├── snapshots/                         # Rolling state snapshots
│   └── YYYY-MM-DD_HHMMSS_state.md    # Timestamped state captures
├── summaries/                         # Completed session summaries
│   └── YYYY-MM-DD_session.md         # Daily session reports
└── next-session/                      # Next session preparation
    └── NEXT_SESSION_START.md         # Auto-updated start document
```

## File Naming Conventions

### Snapshots
- Format: `YYYY-MM-DD_HHMMSS_state.md`
- Example: `2025-12-24_164400_state.md`
- Purpose: Point-in-time state capture during active work
- Created: As needed during complex operations

### Summaries
- Format: `YYYY-MM-DD_session.md`
- Example: `2025-12-24_session.md`
- Purpose: End-of-session comprehensive summary
- Created: At session completion

### Next Session
- Fixed name: `NEXT_SESSION_START.md`
- Purpose: Quick-start guide for next session
- Updated: At session end or major milestones

## Usage Guidelines

### During Active Session
1. Create snapshots before/after major changes
2. Update snapshots during multi-step operations
3. Document decisions and rationale

### At Session End
1. Generate session summary with:
   - Accomplishments
   - Commits made
   - Files modified
   - Issues resolved/discovered
   - Metrics and impact
2. Update NEXT_SESSION_START.md with:
   - Current status
   - Pending tasks
   - Known issues
   - Quick-start commands

### Starting New Session
1. Read `next-session/NEXT_SESSION_START.md`
2. Review latest summary in `summaries/`
3. Check recent snapshots for context

## Retention Policy

- **Snapshots**: Keep last 30 days
- **Summaries**: Keep all (permanent record)
- **Next Session**: Always current (overwrite)

## Integration

All session documents reference:
- `.llmcjf-config.yaml` - LLMCJF configuration
- `llmcjf/` - Behavioral profiles
- Project root documentation

## Automated Workflows (Optional Future Enhancement)

- Pre-session: Auto-generate status from git/CI
- Post-session: Auto-archive snapshots
- Weekly: Generate trend reports
