# Branch Protection & Git Workflow Lab

**Repository:** `devops-journey`

**Target Branch:** `main`

**Feature Branch:** `feat/branch-protection-test`

---

## 1. Overview & Objectives

The goal of this lab session was to:

1. Fix an accidental direct commit to `main` and cleanly move changes onto a feature branch.
2. Force push cleanup to restore `main` to a clean state on GitHub.
3. Enable and enforce **Branch Protection Rules** on GitHub for the `main` branch.
4. Test and confirm that direct pushes to `main` are rejected by GitHub.
5. Safely clean up local test commits after protection verification.

---

## 2. Step-by-Step Lab Execution Log

1. **1. Checking Active Branch:** Branch verification.
Checked active local branches to confirm where work was landing:

```bash
git branch

```


2. **2. Switching to Feature Branch:** Branch switching.
Moved out of `main` into the existing feature branch:

```bash
git checkout feat/branch-protection-test

```


3. **3. Pulling File from Main & Uploading to Branch:** File recovery & workflow.
Extracted `GIT_WORKFLOW.md` from `main` into the feature branch, committed, and set upstream tracking:

```bash
git checkout main -- GIT_WORKFLOW.md
git add GIT_WORKFLOW.md
git commit -m "docs: add Git feature branch workflow guide"
git push -u origin feat/branch-protection-test

```


4. **4. Cleaning Up Accidental Commit on Main:** Main branch cleanup.
Switched back to `main`, rolled back local history by 1 commit, and force-pushed to update remote `main`:

```bash
git checkout main
git reset --hard HEAD~1
git push origin main --force

```


5. **5. Enabling Branch Protection (Repo Visibility):** GitHub settings adjustment.
* **Issue Encountered:** GitHub Free does not enforce Branch Protection on *Private* repositories.
* **Fix:** Converted the repository visibility from **Private** to **Public** in GitHub Settings $\rightarrow$ *Danger Zone*.
* **Configuration:** Added Branch Protection Rule for pattern `main` with *"Require a pull request before merging"* enabled.


6. **6. Syncing Local Main with GitHub:** Remote sync.
Pulled merged cloud updates to bring local `main` into sync with GitHub:

```bash
git pull origin main

```


7. **7. Testing Branch Protection Rules:** Verification test.
Attempted to push a commit directly to `main` from the terminal:

```bash
echo "test branch protection" >> README.md
git commit -am "test: direct push to main"
git push origin main

```

**Result (Expected Failure):**

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Changes must be made through a pull request.
! [remote rejected] main -> main (protected branch hook declined)

```


8. **8. Cleaning Up Local Test Commit:** Local state reset.
Erased the rejected local test commit to return `main` to a clean, synced state:

```bash
git reset --hard HEAD~1
git status

```


---

## 3. Complete Command Cheatsheet (Chronological Reference)

| Order | Command Run | Purpose |
| --- | --- | --- |
| **1** | `git branch` | List local branches and check active branch (`*`). |
| **2** | `git checkout feat/branch-protection-test` | Switch to feature branch. |
| **3** | `git checkout main -- <filename>` | Copy a file from `main` into the current working directory. |
| **4** | `git add <filename>` | Stage modified/new file for commit. |
| **5** | `git commit -m "message"` | Save staged changes into local branch history. |
| **6** | `git push -u origin <branch>` | Upload branch to remote and link upstream tracking. |
| **7** | `git reset --hard HEAD~1` | Completely discard the last commit and wipe local changes. |
| **8** | `git push origin main --force` | Overwrite remote `main` branch with clean local state. |
| **9** | `git stash` | Temporarily shelve uncommitted work to allow branch switching. |
| **10** | `git pull origin main` | Fetch and merge latest cloud changes from GitHub's `main`. |
| **11** | `git status` | Check working directory tree and branch sync status. |

---

## 4. Key Lessons Learned

> * **Syntax Rule:** The `-- ` space separator in `git checkout <branch> -- <file>` is mandatory. Without the space, Git reads the filename as a command option.
> * **GitHub Free Limitation:** Branch protection rules require a **Public** repository when using a free GitHub personal account.
> * **Protection Error (`GH006`):** Seeing `protected branch hook declined` is the target confirmation that branch security is working correctly.
> * **Fast Reset:** `git reset --hard HEAD~1` safely undoes an un-pushed test commit without leaving dirty working tree edits behind.
