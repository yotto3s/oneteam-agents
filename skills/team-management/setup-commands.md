# Team Management: Setup Commands & Procedures

Reference file for bash commands and procedures used during team orchestration.
See [oneteam:skill] `team-management` SKILL.md for the full workflow.

## Git Worktree Creation (Phase 2, Step 2)

For each fragment N (1-indexed):

```bash
# Clean up stale worktree if it exists
git worktree remove ../{{group}}-fragment-N 2>/dev/null
git branch -D {{group}}-fragment-N 2>/dev/null

# Create fresh worktree
git worktree add ../{{group}}-fragment-N -b {{group}}-fragment-N

# Resolve absolute path for agent instructions
WORKTREE_PATH=$(realpath ../{{group}}-fragment-N)
```

After creation, verify each worktree by listing its contents to confirm it is a
valid checkout. If worktree creation fails, check that the branch doesn't already
exist, retry once, then abort with an error to the user.

## Task Creation Guidance (Phase 2, Step 3)

For each fragment, create one task per role defined in `organization.roles`:

- Task subject: `"{group}-{role} fragment N: <fragment description>"`
- For roles where `starts_first: false`, set `addBlockedBy` pointing to the task
  ID of the `starts_first: true` role's task for the same fragment.
- Use `TaskCreate` for each task.
- For **reviewer roles** specifically, create one task per lead group (not per
  fragment), since a reviewer covers all fragments in their lead group. The
  reviewer task subject should be:
  `"{group}-reviewer lead-group-G: review tasks for fragments X-Y"`.
  Do **not** set `addBlockedBy` on the reviewer task for engineer tasks. Keep the
  reviewer task unblocked so the reviewer can perform per-task reviews as
  engineers complete work. Engineers trigger reviews via `SendMessage` to the
  reviewer.

## Agent Spawning Guidance (Phase 2, Step 4)

Iterate over roles in `organization.roles` and spawn agents. Roles fall into two
categories:

### Per-Fragment Roles (most roles)

For each fragment N (1-indexed), spawn one agent:

- Agent name: `{group}-{role}-{N}` (N = fragment index)
- `subagent_type`: from the role's `agent_type` field
- `team_name`: the team name established in step 1

Initialization context MUST include:

- The absolute worktree path for this fragment
- The complete list of files in the fragment (as absolute paths within the
  worktree)
- The names of all other agents working on the same fragment (so they can message
  each other directly)
- The leader's name for escalation messages
- If the plan includes a Team Composition table with reviewer assignments: the
  name of the paired reviewer for this fragment (so the leader knows which
  reviewer to trigger for per-task reviews)
- The role-specific `instructions` from the role definition

### Per-Lead-Group Roles (reviewer roles)

Spawn one agent per lead group rather than per fragment. A lead group is the set
of fragments overseen by the orchestrating lead-engineer (all fragments, for
single-lead setups):

- Agent name: `{group}-{role}-{G}` (G = lead-group index)
- `subagent_type`: from the role's `agent_type` field
- `team_name`: the team name established in step 1

Initialization context MUST include:

- The absolute worktree paths for **all** fragments in the lead group
- The complete file lists for **all** fragments in the lead group
- The names of all engineer agents across fragments in the lead group
- The leader's name for escalation messages
- The role-specific `instructions` from the role definition

### Multi-Group Organizations

For multi-group organizations (where `organization.groups` is an array instead of
a single group): spawn group leaders the same way, passing them their sub-group
configuration so they can further subdivide if needed.

## Merge Protocol (Phase 4, Step 3)

**CRITICAL:** Merge one worktree at a time, sequentially:

```bash
git checkout $BASE_BRANCH
git merge {{group}}-fragment-N --no-ff -m "Merge {{group}}-fragment-N: <fragment description>"
```

After each merge, run the project's test suite to verify nothing is broken. Only
proceed to the next merge after tests pass. If the project has no test suite,
note this in the final report.

### Conflict Resolution (Phase 4, Step 4)

If a merge produces conflicts:

- List conflicted files:
  ```bash
  git diff --name-only --diff-filter=U
  ```
- If 3 or fewer files are conflicted: resolve manually by reading both versions,
  choosing the correct resolution, and editing the files. Run the test suite
  after resolution.
- If more than 3 files are conflicted: abort the merge and delegate:
  ```bash
  git merge --abort
  ```
  Send the conflict details to the agent responsible for the worktree and instruct
  them to rebase their branch onto the updated base branch. Retry the merge after
  the agent completes the rebase.

## Cleanup (Phase 5, Step 2)

Execute all cleanup steps in order:

1. Remove worktrees for each fragment.
2. Delete merged branches (use safe delete `-d` to ensure only fully-merged
   branches are removed).
3. Shut down all agents: send `shutdown_request` via `SendMessage` to each
   spawned agent. Wait for each agent to confirm shutdown before proceeding.
4. Delete the team: if this leader created the team (top-level leader), call
   `TeamDelete` to remove the team and its task list. If working within a parent
   team, skip this step.
