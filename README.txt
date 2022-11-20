I used to use Emacs Org-mode extensively for notes and tasks. I wrote this bash script few years back which runs in background to automatially commit, push/pull to GitHub the changes periodically.

The pseudo-code version:

1. Commit local changes and update remotes.
2. Get latest commit on local repo using 'git rev-parse @'.
3. Similary fetch the latest remote commit using git rev-parse @{u}.
4. Find base with git merge-base @ @{u}
5. If the local commit equals remote commit, then we are done; everything is up-to-date.
6. If the local commit equals the base commit, then the remote has extra commits, and so do git pull.
7. If the remote commit equals the base commit, then the remote has extra commits, and so do git push.
8. If not, both local and remote commits have extra commits. The script attempts to automatically correct this (using git pull), but if it fails, it will sound a bell and exit so the user may fix it themselves.
9. Those eight steps run indefinitely until the script is halted.


Later on, I updated the script so that it can be used for other general purpose repos aswell.