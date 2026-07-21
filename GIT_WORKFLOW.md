## The Mental Model

| Term | Analogy | Real World Purpose |
| --- | --- | --- |
| **`main`** | The Published Book | Live, working code. Must **never** be broken directly. |
| **Feature Branch** | A Scratchpad / Photocopy | An isolated space where you can write, test, and break things safely. |
| **`origin`** | Google Drive / Cloud | The central server (GitHub) where everyone shares code. |
| **`git push -u`** | The First Upload | Sends your scratchpad to the cloud and links your local draft to the cloud draft. |
| **Branch Protection** | The Gatekeeper | GitHub rules requiring code review & tests before anything enters `main`. |
| **Pull Request (PR)** | The Formal Proposal | Asking your team: *"Review my draft and merge it into `main` for me."* |

---

## The Standard Step-by-Step Workflow

1. **1. Sync your local main:** Always start clean.
Before starting anything new, ensure your local `main` matches what's on GitHub:

```bash
git checkout main
git pull

```


2. **2. Create & switch to a feature branch:** Isolated workspace.
Create a fresh photocopy of `main` under a clear, descriptive name:

```bash
git checkout -b feat/branch-protection-test

```


3. **3. Write code & save local snapshots:** Your work.
Make your edits in your code editor. When ready, take a local snapshot:

```bash
git add .
git commit -m "add initial branch protection test setup"

```


4. **4. Push and set upstream tracking:** Cloud upload & tracking.
Upload your branch to GitHub for the first time using `-u` (`--set-upstream`):

```bash
git push -u origin feat/branch-protection-test

```

*(From now on on this branch, you only need to type `git push` or `git pull`.)*


5. **5. Open a Pull Request on GitHub:** GitHub review.
Go to GitHub in your browser. You will see a banner prompting you to **"Compare & pull request"**.

* Describe what changes you made.
* Submit the PR for review.
* Let automated tests (CI/CD) run and teammates approve it.


6. **6. Merge & clean up:** Completion.
* Once approved, click **Merge Pull Request** on GitHub.
* Back on your computer, switch to `main` and pull the newly merged code:

```bash
git checkout main
git pull

```


---

## Essential Command Cheatsheet

| Goal | Command | What It Actually Does |
| --- | --- | --- |
| **Check current status** | `git status` | Shows modified files and current branch |
| **List branches** | `git branch` | Lists local branches (active branch marked with `*`) |
| **Switch branch** | `git checkout <branch>` | Moves your working directory to an existing branch |
| **Create & switch** | `git checkout -b <branch>` | Creates a new branch and moves you to it immediately |
| **Stage all changes** | `git add .` | Stages all modified and new files for snapshotting |
| **Save snapshot** | `git commit -m "msg"` | Saves staged changes into local Git history |
| **First push** | `git push -u origin <branch>` | Uploads branch to GitHub & sets default tracking link |
| **Subsequent pushes** | `git push` | Uploads new commits using the established tracking link |
| **Download updates** | `git pull` | Downloads & merges latest cloud changes into current branch |

---
