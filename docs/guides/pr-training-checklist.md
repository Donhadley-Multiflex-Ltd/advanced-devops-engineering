# Training Pull Request Checklist

## Purpose

Practice raising, reviewing, updating, and merging a pull request
using the team's agreed workflow.

- Assigned task: [SCRUM-36](https://donhadleygirlandchika.atlassian.net/browse/SCRUM-36)
- Parent story: [SCRUM-33](https://donhadleygirlandchika.atlassian.net/browse/SCRUM-33)
- Author: Alexander Njoku

Use this checklist alongside the repository's pull request template
and agreed review requirements.

## Prepare the Change

- [ ] Read the assigned Jira task and acceptance criteria.
- [ ] Create a working branch from the latest main.
- [ ] Follow the team's agreed branch naming convention.
- [ ] Make a focused change related to the task.
- [ ] Review the changed content for accuracy.
- [ ] Include the Jira issue key in the commit message.
- [ ] Make the commit available on GitHub.

For local Git work, push the branch to GitHub.
A commit created through GitHub's web editor does not demonstrate
running git push locally.

## Open the Pull Request

- [ ] Set main as the target branch.
- [ ] Select the working branch as the source.
- [ ] Include SCRUM-36 in the pull request title.
- [ ] Complete the repository's pull request template.
- [ ] Explain what changed and why.
- [ ] Link the associated Jira task.
- [ ] Request a reviewer.

## Validate the Documentation

- [ ] Preview the Markdown formatting.
- [ ] Verify the document's links.
- [ ] Check the Files changed tab for unintended changes.
- [ ] Confirm no credentials or sensitive information were added.
- [ ] Record the validation actually performed in the pull request.
- [ ] Check any required automated checks and investigate failures.

Do not claim tests passed unless they were run successfully.
For documentation-only changes, explain which validation was performed
and whether application tests were run.

## Respond to Review

- [ ] Read the reviewer's feedback.
- [ ] Reply to questions and requested changes.
- [ ] Update the same working branch when changes are needed.
- [ ] Request another review after addressing feedback.
- [ ] Confirm required feedback has been addressed.

## Merge and Close Out

- [ ] Obtain the required review approval.
- [ ] Satisfy the team's validation and merge requirements.
- [ ] Have the authorized maintainer merge the pull request.
- [ ] Delete the source branch after merge where appropriate.
- [ ] Add the pull request and supporting evidence to Jira.
- [ ] Update the Jira task according to the team's completion rules.

A conflict-free pull request still requires review and validation
before merging.

## Evidence to Record

- Working branch link
- Commit link
- Pull request link
- Review and feedback
- Responses and follow-up commits, if applicable
- Validation results
- Merge confirmation when completed

Keep checklist items unchecked until the corresponding work is complete.
