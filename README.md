# backup
Powershell scripts to backup Windows10 laptop's SSD on C:\ to HDD on D:\. It uses maximal compression (i.e., runtime be damned), runs automatically when the "sleep" state is called, and keeps only:
- the previous 3 backups
- a backup for each of the previous 3 months
- a backup for each of the previous 3 years
