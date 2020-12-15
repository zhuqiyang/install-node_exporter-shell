#!/bin/bash

for var in `cat host_ips`
do

ssh $var 'cat /etc/redhat-release'

done
