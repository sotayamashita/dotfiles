---
name: show-plan
description: "Presents a plan as one self-contained HTML page in plain words, for a reader who did not see the conversation. Use when you present, propose, or revise a plan for the user to approve, even when the user does not ask for HTML. Do not use it to explain existing code or to report results."
---

# show-plan

Show a plan as one HTML page. The reader is the user on another day, without the conversation. The page must make sense to that reader alone.

## Write for a reader without context

The reader knows the domain, but not this conversation. A reader stops when the page needs the chat, so remove each such dependency.

- Restate each fact that the plan depends on.
- Do not use words that refer to the conversation, such as "this time" or "the earlier idea".
- Do not name an option, a task, or a case only by its label, such as "option B" or "cfa-02".
- Describe it in words, and add the label only when the reader must find it.
- Give each code name, file name, and ID a plain description, next to it or in the glossary.
- Do not show JSON or a table of code names without a plain description of each row.
- Use plain words, and write one idea in each sentence.
- Write the page in the language of the conversation.

## Make the page short

A reader stops on a long page. Make the important part easy to find.

- Keep the visible text to about 3,000 Japanese characters or 600 English words.
- Put a key-points box under the lead, with three points or fewer.
- Write the key points so that a reader who reads only this box knows what the plan does.
- Write one sentence for each step, card, and option.
- Mark the most important words in each step, card, and option with `<mark>`.
- Mark one place in each step, card, or option, because more marks hide the important one.
- Use a picture, a table, or a before-and-after instead of a paragraph when possible.
- Put seven steps or fewer in one list, and group the steps when there are more.

## Write only what the plan needs

A reader asks "why is this necessary?" about each part without a reason. Give each step and each check a reason that the reader can see. Remove a part that has no reason.

- Use one good example, not three weak examples.
- Show real content in each option and example, not an empty box or an abstract label.
- Mark a place in a picture or a sheet with a numbered red frame.
- Use the same number in the text.
- Put a long command in a code block.
- Use color only for meaning: an actor, a status, or before and after.

## Structure

Use these sections in this order. Leave out a section that does not apply. Number the headings from 1 with no gaps.

1. Title, lead, and key-points box: the plan name, one sentence about the result of the plan, and the key points.
2. Words: a glossary of each term that the reader possibly does not know.
3. Problem: what does not work today, when the lead does not make it clear.
4. Rules to keep: the constraints that each step must obey.
5. Where things are kept: the places for data and files, when a boundary is important.
6. Steps: a numbered list with an actor badge, a bold action, and one sentence for each step.
7. Example: one before-and-after, side by side, with real values.
8. Checks: how we know that the result is correct.
9. What we make: the files or parts to add, change, or delete, each with a plain comment.
10. Order of work: the milestones, and the places where the work stops for review.
11. Not doing: each option that the plan rejects, with its reason.
12. Decisions: the open questions and the decided answers.

Use the same actor badge colors on the whole page: blue for a script, purple for an AI agent, amber for Claude, and green for a person.

## Decisions

For each open question, show the effect of each option on the current state. Show the good points and the bad points of each option. Give a recommendation and its reason. Use the option cards in the template when a picture shows the difference between the options.

Mark each decision as decided, tentative, or open. Mark a decision as decided when the user gave an answer.

## Build the page

Copy `assets/plan.html` and replace its sample content. The template has the CSS and one example of each component. Keep the CSS, and delete the components that you do not use.

Draw sheets, tables, and screens with static HTML and CSS, not with JavaScript, so that the source shows the content. When the plan changes a screen of an app, copy the appearance of that part of the screen. Do not load fonts, scripts, or styles from the network.

Save the page as `/tmp/show-plan-<short-slug>.html`.

## Examine the page before you open it

Run the lint script from the skill directory:

```bash
uv run scripts/lint.py /tmp/show-plan-<short-slug>.html
```

The script does the checks that do not need judgment. It writes JSON to stdout and exits with 1 when a check fails. Correct each failed check, and run the script again until it exits with 0. Run `uv run scripts/lint.py --help` for the details of each check.

Then read the whole page as a person who did not see the chat. Do these checks, because a script cannot do them:

- Read only the key-points box and the marked words, and make sure that they tell the plan.
- Find each code name and ID, and make sure that it has a plain description.
- Make sure that each reference such as "step 3" goes to the correct place.

Then open the page with `open <path>`.

## Revise the same page

When the plan changes, edit the same file and open it again. Show only the current plan, with no change log. Move a rejected option to "Not doing" with its reason. The reader must know why the plan does not include it.

## Chat reply

The page contains the plan, so keep the chat reply to about 400 Japanese characters or fewer. Write these items only:

- The path of the page.
- On a revision, what changed, in three bullets or fewer.
- Each open decision, in one line.

Do not repeat the key points or the steps in the chat.
