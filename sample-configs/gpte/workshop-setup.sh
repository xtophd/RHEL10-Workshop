#!/bin/bash

## This script is meant to be run as root (ie: sudo) 
## to complete the setup of this workshop for environments
## runnning in the RH demo platform.

## Change directory to the project root

cd /root/RHEL10-Workshop 

## Run the playbooks

./rhel10-workshop.sh all
