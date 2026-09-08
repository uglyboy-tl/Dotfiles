#!/bin/bash

notmuch search --output=files tag:unread | grep -c '/INBOX/'
