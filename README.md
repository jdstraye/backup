# backup
Powershell scripts to backup Windows10 laptop's SSD on C:\ to HDD on D:\. It uses maximal compression (i.e., runtime be damned), runs automatically when the "sleep" state is called, and keeps only:
- the previous 3 backups
- a backup for each of the previous 3 months
- a backup for each of the previous 3 years

# Disontinuation
I could never get the archival process fast enough to make it viable. So, I am discontinuing this effort to throw my efforts behind [restic](https://github.com/restic/restic). There are many helper git repos for restic, also, such as 
- [djmaze/resticker] (https://github.com/djmaze/resticker). Run automatic restic backups via a Docker container.
- [kmwoley/restic-windows-backup](https://github.com/kmwoley/restic-windows-backup). Powershell scripts to run Restic backups on Windows

