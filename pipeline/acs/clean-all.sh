#!/bin/bash -x
# Clean up everything

./clean.sh

oc delete -f task 

#oc delete -f gitea 

#oc delete -f sonar 

oc delete project vote-app-dev 

