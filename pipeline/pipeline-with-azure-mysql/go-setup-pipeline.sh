#!/bin/bash -xe 
# Converted from https://docs.openshift.com/container-platform/4.5/pipelines/creating-applications-with-cicd-pipelines.html 

# Set the project name
P=aso-demo

oc project $P || oc new-project $P 

# Set up tasks
# From: oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/release-tech-preview-2/01_pipeline/01_apply_manifest_task.yaml
# From: oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/release-tech-preview-2/01_pipeline/02_update_deployment_task.yaml
oc get task apply-manifests   || oc create -f apply_manifest_task.yaml
oc get task update-deployment || oc create -f update-deployment-task.yaml
# Set up my own tasks
oc get task update-deployment-set-env || oc create -f update-deployment-set-env-task.yaml
oc get task smoke-test-task || oc create -f smoke-test-task.yaml

# Check
oc get serviceaccount pipeline
tkn task list

# Use this buildah ClusterTask which is more up-to-date
#### From: oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/release-tech-preview-2/01_pipeline/04_pipeline.yaml
oc get task buildah-new || oc create -f buildah.yaml   # "buildah-new"

# Create the pipeline
oc get pipeline vote-app-build-and-deploy || oc create -f vote-app-build-and-deploy-pipeline.yaml
tkn pipeline  list

oc get pvc source-pvc || oc create -f persistent_volume_claim.yaml

######
# Set up "delete" pipeline
oc create -f vote-app-cleanup-task.yaml
oc create -f vote-app-delete-pipeline.yaml
######

# Start the pipeline (seems no way to start this from the 4.4 console as cannot define the workspace VPC)
#tkn pipeline start vote-app-build-and-deploy \
#	-w name=shared-workspace,claimName=source-pvc \
#	-p deployment-name=vote-app \
#	-p git-url=https://github.com/sjbylo/flask-vote-app.git \
#	-p IMAGE=image-registry.openshift-image-registry.svc:5000/$P/vote-app \
#	--showlog

# Clean up
#oc delete po,pipeline,pipelinerun,taskrun,task,pipelineresource  --all 

