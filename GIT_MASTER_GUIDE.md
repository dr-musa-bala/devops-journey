# The Ultimate Git & GitHub Master Guide

## 1. Mental Model: How Git Actually Works

To master Git, remember that code moves across **3 independent levels**:

```text
[ 1. Working Directory ]  --->  [ 2. Local Branch History ]  --->  [ 3. GitHub / Origin ]
     (Your Desk/Files)                (Local Commit Ledger)             (Cloud Storage)

```

| Concept | What It Actually Is | Analogy |
| --- | --- | --- |
| **`main`** | The production branch | The published book (must **never** be broken). |
| **Feature Branch** | An isolated copy of `main` | A temporary draft/scratchpad to test changes. |
| **`origin`** | The remote GitHub server | The central cloud repository where the team syncs. |
| **`git add`** | Staging | Putting documents into an envelope before sealing it. |
| **`git commit`** | Local snapshot | Sealing the envelope and stamping it into your local ledger. |
| **`git push`** | Cloud upload | Mailing the sealed envelope to GitHub headquarters. |
| **`git pull`** | Cloud download | Downloading new updates from GitHub headquarters. |

---

## 2. Core Syntax Rules Explained

### Why `git push -u origin <branch>`?

* **`-u`** stands for **`--set-upstream`**.
* When you create a new branch locally, GitHub doesn't know it exists yet.
* `-u` creates a permanent tracking link between your local branch and GitHub's remote branch.
* **Benefit:** On subsequent pushes or pulls on this branch, you only need to type **`git push`** or **`git pull`**.

### Why the `--` separator (`git checkout main -- <file>`)?

* In Git, `--` tells the terminal: *"Stop looking for command options/flags; everything after this space is a literal filename."*
* Example: `git checkout main -- GIT_WORKFLOW.md` copies `GIT_WORKFLOW.md` out of `main` directly onto your current working branch.

---

## 3. Standard Feature Branch & PR Workflow

Follow this sequence every time you build a feature, write documentation, or fix a bug:

1. **1. Start from updated main:** Sync local main.
Switch to `main` and pull the latest changes from your team:

```bash
git checkout main
git pull

```


2. **2. Create & switch to feature branch:** Create isolated space.
Create a fresh branch using `-b` (create and checkout):

```bash
git checkout -b feat/branch-protection-test

```


3. **3. Make changes & stage files:** Write code.
Edit your files in your editor, then stage them:

```bash
git add .

```

*(Or stage a specific file: `git add GIT_WORKFLOW.md`)*


4. **4. Commit locally:** Local snapshot.
Save your progress to your local branch ledger:

```bash
git commit -m "docs: add Git workflow documentation"

```


5. **5. First push with upstream tracking:** Cloud upload.
Upload your branch to GitHub and link it:

```bash
git push -u origin feat/branch-protection-test

```


6. **6. Open Pull Request on GitHub:** Review & merge.
* Go to GitHub and click **Compare & pull request**.
* Request reviews and let automated checks pass.
* Click **Merge Pull Request** once approved.


---

## 4. Recovery Guide: Undoing an Accidental Push to `main`

If you accidentally committed and pushed directly to `main` instead of a feature branch, use this safe 5-step recovery sequence:

1. **1. Copy file to feature branch:** Protect your work.
Switch to your feature branch and pull the file out of `main`:

```bash
git checkout feat/branch-protection-test
git checkout main -- GIT_WORKFLOW.md

```


2. **2. Commit & push on feature branch:** Save on feature branch.
Stage, commit, and push the file on the correct branch:

```bash
git add GIT_WORKFLOW.md
git commit -m "docs: add Git workflow documentation"
git push -u origin feat/branch-protection-test

```


3. **3. Return to main:** Switch to main.
Switch back to `main` to clean up local history:

```bash
git checkout main

```


4. **4. Roll back last commit on main:** Local reset.
Remove the accidental commit from local `main`:

```bash
git reset --hard HEAD~1

```


5. **5. Force push main to GitHub:** Remote cleanup.
Overwrite GitHub's `main` branch to match your clean local state:

```bash
git push origin main --force

```


---

## 5. Master Command Cheatsheet

| Category | Command | What It Does |
| --- | --- | --- |
| **Branching** | `git branch` | Lists local branches (active branch marked with `*`) |
|  | `git checkout <branch>` | Switches to an existing branch |
|  | `git checkout -b <branch>` | Creates and switches to a **new** branch |
| **Status & Staging** | `git status` | Shows modified, untracked, and staged files |
|  | `git add <file>` | Stages a specific file for commit |
|  | `git add .` | Stages **all** modified and new files |
| **Committing** | `git commit -m "message"` | Saves staged snapshot into local branch history |
| **Pushing** | `git push -u origin <branch>` | Uploads branch to GitHub & sets upstream tracking |
|  | `git push` | Uploads new commits on an already-tracked branch |
|  | `git push origin main --force` | Overwrites remote `main` to match local state *(Use with care)* |
| **Pulling** | `git pull` | Downloads & merges latest cloud changes into current branch |
|  | `git pull origin main` | Pulls latest updates from `main` into your active feature branch |
| **Undoing** | `git reset --hard HEAD~1` | Erases the last commit and discards local changes |
|  | `git checkout main -- <file>` | Restores/copies a file from `main` into current working directory |

---

> **Pro Tip:** Before doing any major Git operation, run `git status` and `git branch`. Knowing **where you stand** and **what files are changed** prevents 90% of Git errors!