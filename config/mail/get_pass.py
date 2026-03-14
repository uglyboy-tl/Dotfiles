#! /usr/bin/env python3
from subprocess import check_output
import os


def get_pass(key):
    env = os.environ.copy()
    env["GNUPGHOME"] = os.path.expanduser("~/.local/share/gnupg")
    return check_output(["pass", "show", key], env=env).rstrip(b"\n")
