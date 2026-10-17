# Git Branch Types and Branching Strategy

Status: Proposed — pending team review.
Jira task: SCRUM-29
Parent story: SCRUM-28
Related verification task: SCRUM-32

## Purpose

Describe branch types and propose a consistent workflow so changes can
be developed, reviewed, and merged while maintaining main branch stability.

## Proposed Branch Types

| Type | Purpose | Lifetime |
| --- | --- | --- |
| Main | Holds reviewed and integrated project changes. | Long-lived |
| Feature | Develops new functionality or infrastructure capabilities. | Short-lived |
| Bug fix | Corrects an identified defect. | Short-lived |
| Documentation | Updates guides, READMEs, and other documentation. | Short-lived |
| Maintenance | Updates tooling, dependencies, or repository configuration. | Short-lived |

These types describe the purpose of the work. Under the proposed naming
format below, a type prefix such as feature/ or docs/ is not required.

A develop branch, release branches, and hotfix branches are not included
in this initial proposal. The team can introduce them if needed.

## Observed Repository Naming

An existing branch uses this name:

SCRUM-27-devops-001-d-create-initial-readme

This is an observed example, not confirmation of an approved naming policy.

## Proposed Naming Convention

For task branches, use:

<JIRA-KEY>-<task-code>-<short-description>

Example for this documentation task:

SCRUM-29-devops-002-a-document-branch-types

Proposed rules:

- Use the actual Jira issue key in uppercase, such as SCRUM-29.
- Use the task code from the issue title in lowercase, such as devops-002-a.
- Write a short, meaningful description in lowercase.
- Separate words and components with hyphens.
- Do not use spaces.
- Keep the name relevant to the linked task.
- Exempt main from the task-branch naming format.

The team must confirm this convention and any additional exceptions
before it is used as the compliance standard for SCRUM-32.

## Proposed Workflow

1. Select the assigned Jira task and review its requirements.
2. Create a short-lived working branch from the latest main.
3. Make focused changes related to the task.
4. Review the changes and perform applicable validation.
5. Commit with the Jira issue key in the message.
6. Push the branch to GitHub.
7. Open a pull request targeting main and link the Jira task.
8. Address review feedback and satisfy required checks.
9. Have an authorized maintainer merge the reviewed change.
10. Record the evidence in Jira and update the task status.

Proposed policy: changes to main should go through a reviewed pull request.
This document does not configure or confirm GitHub branch protection.

## Evidence

Record the following links in the relevant Jira task:

- Working branch
- Commit
- Changed documentation
- Pull request

If the exercise requires a command-line push, retain evidence of that
push. Creating or editing a branch through GitHub's website does not
demonstrate running git push locally.

## Branch Naming Verification

After the team approves the naming convention, SCRUM-32 should record:

- The approved rule and its source.
- The branches included in the review.
- The review date.
- Each branch's result: compliant, noncompliant, or exempt.
- The reason for each result and any follow-up required.

Do not rename or delete another contributor's branch without coordination.

## Review Decisions Needed

- Confirm the proposed branch types.
- Confirm the naming format and exceptions.
- Confirm main as the source and pull-request target for task branches.
- Confirm review and merge requirements.
- Confirm which branches SCRUM-32 must inspect.
