#!/bin/bash -x

P=vote-app-dev   # Project name cannot be changed 

oc new-project $P >/dev/null || oc project $P || exit 1

oc get secret roxsecrets >/dev/null 2>&1 || oc get secret roxsecrets -o yaml -n stackrox-pipeline-demo | grep -v '^\s*namespace:\s' | oc create -f - || exit 1

oc create -f task 

# Secret, needed to commit/push to repo
oc create -f secret 

oc create -f pipeline.yaml

oc delete pipelinerun vote-app-dev-pipelinerun 2>/dev/null

oc create -f pipelinerun.yaml

# Download tkn CLI from OpenShift Console
tkn pipelinerun logs -L -f

