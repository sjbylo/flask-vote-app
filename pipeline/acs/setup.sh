#!/bin/bash -x

P=vote-app-dev

oc new-project $P >/dev/null || oc project $P || exit 1

oc get secret roxsecrets >/dev/null 2>&1 || oc get secret roxsecrets -o yaml -n stackrox-pipeline-demo | grep -v '^\s*namespace:\s' | oc create -f - || exit 1

oc create -f task >/dev/null

# Secret, needed to commit/push to repo
oc create -f secret >/dev/null

oc create -f pipeline.yaml

oc delete pipelinerun pipelinerun >/dev/null

#sed "s#/project_name/#/`oc project -q`/#g" < vote-app-pipelinerun-acs.yaml | oc create -f - 
oc create -f pipelinerun.yaml

tkn pipelinerun logs -L -f

