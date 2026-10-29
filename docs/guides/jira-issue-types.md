# Jira Issue Types: Team Quick Reference

Use this guide when creating or reviewing Jira issues so the team classifies work consistently.

## Purpose and Differences

| Issue type | Purpose and when to use it | DevOps project example |
| --- | --- | --- |
| **Epic** | Groups related work toward a larger outcome. Break it into Stories, Tasks, and Bugs as needed; it may span several sprints. | Establish an automated CI/CD delivery platform. |
| **Story** | Describes a small, testable outcome that benefits a user or stakeholder, including an internal engineer. Focus on the capability and its value. | As a developer, I want pull requests validated automatically so I receive feedback before merging. |
| **Task** | Tracks a concrete piece of technical, operational, or documentation work. Use when describing the work directly is clearer than a user story. | Create a pull request template in the repository. |
| **Subtask** | Breaks a standard issue into smaller steps. It requires a parent issue and contributes to that parent's completion. | Under the PR template Task: document the Jira ticket field. |
| **Bug** | Records behavior that differs from an agreed requirement or expected behavior. Use to track a defect, rather than a request for a new capability. | The pull request validation workflow fails to run when a PR opens. |
| **Spike** | Tracks a time-boxed investigation to reduce uncertainty before committing to implementation. Its output is documented findings, a recommendation, or a better estimate. | Compare Argo CD deployment approaches in one day and document a recommendation. |

## How the Types Relate

In Jira's default hierarchy:

| Level | Types | Relationship |
| --- | --- | --- |
| Larger outcome | Epic | Groups standard issues. |
| Standard work | Story, Task, Bug; Spike if configured at this level | Can belong to an Epic and can have Subtasks. |
| Smaller step | Subtask | Belongs to a standard parent issue; cannot have its own Subtasks. |

**A Task is not automatically a child of a Story.** They are peers in the default hierarchy. To break a Story into implementation steps, use Subtasks. Use issue links for related standard issues.

**Spike is not a default Jira Software issue type.** If it is unavailable, use a Task with a `spike` label and a clear research title, or ask the Jira administrator to configure it. Available types and hierarchy depend on project settings.

## Quick Selection Rules

- **Several related deliverables toward one outcome?** Use an Epic.
- **A user or stakeholder needs a testable capability?** Use a Story.
- **A concrete piece of work needs completing?** Use a Task.
- **A smaller step belongs within an existing issue?** Use a Subtask.
- **Actual behavior does not match expected behavior?** Use a Bug.
- **A question must be answered before implementation can be planned?** Use a Spike.

Choose by purpose, not effort alone: a small defect is still a Bug, and a large Task may need splitting.

## What to Include

Every issue should state its purpose and completion criteria. For a Story, make the benefit and acceptance criteria clear. For a Bug, include reproduction steps, expected versus actual behavior, and relevant logs or screenshots. For a Spike, specify the question, time limit, and required findings; create follow-up implementation issues from the results.

## References

- [Atlassian: Work types and default hierarchy](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/)
- [Atlassian: Using spikes to reduce uncertainty](https://www.atlassian.com/blog/development/inside-atlassian-building-products-devops)

