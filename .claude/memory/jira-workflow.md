# The Jira board

Work runs ticket by ticket from the owner's own Jira — project **`KAN`
("Team Helo")** on their HeloCode Atlassian site. It is their personal
instance, reached through the Atlassian connector; do not assume a company
board.

```
To Do → In Progress → QA Ready → QA In Progress ─┬→ Done
                          ↑                      └→ QA Failed
                          └──────────────────────────┘
```

## Movement is forward-only

The one exception is **QA Failed → In Progress**, so failed work re-enters the
dev stage and travels the whole path again. The complete allowed set is exactly
six transitions:

`To Do→In Progress`, `In Progress→QA Ready`, `QA Ready→QA In Progress`,
`QA In Progress→Done`, `QA In Progress→QA Failed`, `QA Failed→In Progress`.

**Why:** the board should reflect true progress rather than letting tickets be
dragged backwards, so status history stays a reliable record of where work
actually went.

**How to apply:** create issues in `To Do`. Advance one step at a time — never
skip a stage, never propose a backwards move. The API refuses anything else, so
reaching Done from To Do takes four calls.

There is also a **Dev Hold** status for work deliberately parked.

## "Clear the board"

An established instruction meaning **move everything in QA Ready to Done**.
Nothing else moves.

## Bugs

The board has a **Bug** type. The rule the owner set: **only raise a Bug for
something important. Fix small ones directly, with no ticket.**

**Why:** they are one person. A board full of trivia costs more to maintain
than it returns, and buries the defects that actually threaten a release.

Ticket-worthy means: it loses or corrupts user data, blocks a release, is
visible to testers or users, or would otherwise be rediscovered by someone
else. Typos, dead code, cosmetic drift, anything fixable inside the change
already in hand — just fix it and say so in the commit.

## Writing tickets here

Tickets on this board carry the reasoning, not just the task: what is wrong,
why it matters, what was decided against, and what "done" looks like. They are
read weeks later by the same person who wrote them, with no one else to ask.
Epics are `KAN-6`..`KAN-11`; monetisation work hangs off `KAN-10` with the
`monetisation` label.
