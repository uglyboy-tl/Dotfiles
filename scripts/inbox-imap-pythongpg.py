#!/usr/bin/python3

import imaplib
import os
import subprocess

IMAP_DICT = {
    "uglyboy@aliyun.com": "imap.aliyun.com",
    "uglyboy@uglyboy.cn": "imap.uglyboy.cn",
}

unread_count = 0

for email, imap_url in IMAP_DICT.items():
    completed_process = subprocess.run(['gpg', '-dq', os.path.join(os.getenv('HOME'), f'.password/{email}.gpg')], check=True, stdout=subprocess.PIPE, encoding="utf-8")
    password = completed_process.stdout[:-1]
    obj = imaplib.IMAP4_SSL(imap_url, 993)
    # Only put your email address below.
    obj.login(email, password)
    obj.select('INBOX')

    unread_count += len(obj.search(None, 'UNSEEN')[1][0].split())

print(unread_count)