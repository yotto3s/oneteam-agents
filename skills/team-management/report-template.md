# Team Management: Report Template & Organization Examples

Reference file for the final report template and organization structure examples.
See [oneteam:skill] `team-management` SKILL.md for the full workflow.

## Team Report Template (Phase 5)

Use this template for the final report, inserting the leader's `report_fields`
and `domain_summary_sections` where indicated. Every section is mandatory -- none
may be omitted. If there are no unresolved items, write "None" in the table body.

```
## Team Report

**Scope:** <what was analyzed or worked on>
**Base branch:** <branch name>
**Fragments completed:** N / N

[Insert leader's report_fields here, if any]

### Per Fragment

#### Fragment 1: <name>
- **Agents:** {group}-{roleA}-1, {group}-{roleB}-1, ...
- **Branch:** {group}-fragment-1
- **Tasks completed:** M / M
- **Summary:** <brief description of what was accomplished>

#### Fragment 2: <name>
- **Agents:** {group}-{role}-2, ...
- **Branch:** {group}-fragment-2
- **Tasks completed:** M / M
- **Summary:** <brief description>

...

### Unresolved Items
| Item | Fragment | Description | Reason |
|------|----------|-------------|--------|
| <item> | <N> | <what was attempted> | <why it was not resolved> |

[Insert leader's domain_summary_sections here, if any]
```

## Organization Structure Example

This example demonstrates the versatility of the slot system for multi-group use
cases. For single-group examples (debugging, feature development), see the domain
configurations in [oneteam:agent] `lead-engineer`.

### Multi-Group Project

A pipeline of three groups where each group has its own leader. The planning
group produces a plan, the feature group implements it, and the debug group
verifies the result. Each group leader can further subdivide work internally.

```yaml
organization:
  groups:
    - group: "planning"
      roles:
        - name: "lead"
          agent_type: "planning-team-leader"
          starts_first: true
          instructions: "Analyze requirements, produce implementation plan"
    - group: "feature"
      roles:
        - name: "lead"
          agent_type: "feature-team-leader"
          starts_first: false
          instructions: "Implement features per plan from planning lead"
    - group: "debug"
      roles:
        - name: "lead"
          agent_type: "[oneteam:agent] lead-engineer"
          starts_first: false
          instructions: "Run debugging sweep on completed features"
  flow: "planning-lead plans -> feature-lead builds -> debug-lead verifies"
```

Agent naming: `planning-lead-1`, `feature-lead-1`, `debug-lead-1`. Each group
leader can spawn their own sub-agents within the same flat team, using their
group prefix (e.g., `feature-junior-engineer-1`, `feature-senior-engineer-1`).

Task dependencies chain across groups: `feature-lead-1` is blocked by
`planning-lead-1`, and `debug-lead-1` is blocked by `feature-lead-1`. This
ensures the pipeline executes in the correct order while still allowing
parallelism within each group.
