#! /usr/bin/env python3
from subprocess import check_output

def get_pass(username):
    return check_output(f"gpg -dq ~/.local/share/password/{username}.gpg", shell=True).rstrip(b"\n")