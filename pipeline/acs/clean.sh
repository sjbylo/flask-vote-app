#!/bin/bash -x
# Clean up the pipeline only

P=vote-app-dev   # Project name cannot be changed 

# Secret, needed to commit/push to repo
oc delete -f secret -n $P

oc delete -f pipeline.yaml -n $P

oc delete pipelinerun vote-app-dev-pipelinerun 2>/dev/null -n $P

