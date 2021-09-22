#!/usr/bin/env bash

USERID=$(tctl get user | grep $PREFIX | awk '{print $1}')
export TCTL_USERID=${USERID}
