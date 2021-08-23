#!/bin/bash -x
# Clean up everything

./clean.sh

oc delete -f task 

oc delete -f secret 

oc delete -f pipeline.yaml

oc delete -f pipelinerun.yaml

#oc delete -f gitea 

#oc delete -f sonar 

oc delete project vote-app-dev 

