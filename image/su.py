#!/usr/bin/env python3
import os, sys, pwd, grp

u=pwd.getpwnam(sys.argv[1])
cmd=sys.argv[2:]
groups=[ g.gr_gid for g in grp.getgrall() if u.pw_name in g.gr_mem ]
groups.append(u.pw_gid)

os.setgroups(groups)
os.setgid(u.pw_gid)
os.setuid(u.pw_uid)
os.execvp(cmd[0], cmd)
