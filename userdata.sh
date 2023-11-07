#!/bin/bash

set-hostname -skip-apply ${component}
sudo labauto ansible
ansible-pull -i localhost, -U https://github.com/rpraveenkumar1220/Roboshop-Ansible.git  roboshop.yml -e env=${env} -e role_name=${component} &>> /opt/ansible.log
