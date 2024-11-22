#! /usr/bin/env python3
from subprocess import check_output
import os

def get_pass(username):
    env = os.environ.copy()
    env['GNUPGHOME'] = '~/.local/share/gnupg'
    return check_output(f"gpg -dq ~/.local/share/password/{username}.gpg", env=env, shell=True).rstrip(b"\n")