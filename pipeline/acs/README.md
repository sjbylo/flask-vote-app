# Demo Pipeline using roxctl 

This demo shows the use of roxctl in a Tekton Pipeline.  Is shows scanning/checking a freshly built 
image for CVEs and checking the app deployment manifest for bad practices. 

The demo uses a repo with a simple python application.
The master branch causes no failures but the "cve" git reference causes roxctl checks to fail.

The branch can be chosen when starting the pipeline.


## Set up the Demo

First, spin up a demo cluster for Advanced Cluster Security (ACS) in RHPDS (warning, internal tool).

Set up Gitea on the cluster (instructions in gitea/) and migrate this git repo to it. 

Example git repo:

```
https://simple-gitea-gitea.apps.cluster-s9tpk.s9tpk.sandbox222.opentlc.com/demo/flask-vote-app.git
```

Configure the git repo URL and hostname in all the needed files:

```
./pipelinerun.yaml
./secret/git-basic-auth-secret.yaml
./gitops/argo-application.yaml
```

Set up the secret `secret/git-basic-auth-secret.yaml` to access the git repo you want to use. 


If you're really impatient, you can try to run the "./setup.sh" script.

Following are the manual steps.

## Set up as cluster-admin 

Create a demo project.  At the moment, the project needs to be named vote-app-dev.

```
oc new-project vote-app-dev
```

Copy the provided ACS demo secret over (or export credentials from the ACS Console) 

```
oc get secret roxsecrets -o yaml -n stackrox-pipeline-demo | grep -v '^\s*namespace:\s' | oc create -f -
```

Some of the provided demo cluster tasks have been modified so add them:

```
oc create -f task
```

Create the secret for your repo:

```
oc create -f secret
```

Create the pipeline

```
oc create -f vote-app-pipeline-acs.yaml
```

To start the pipeline, use the following PipelineRun resource or to it from the OpenShift Console (remember to create and add a PVC) 

```
#oc create -f vote-app-pipelinerun-acs.yaml
sed "s#/project_name/#`oc project -q`#g" < vote-app-pipelinerun-acs.yaml | oc create -f - 
```

View the pipeline output with tkn (download tkn from the OpenShift Console)

```
tkn pipelinerun logs -L -f
```

To restart the pipeline run:

```
oc delete pipelinerun vote-app-dev-pipelinerun -n vote-app-dev && oc create -f pipelinerun.yaml -n vote-app-dev
```


## Troubleshooting

Sometimes a 401 error can be seen when `roxctl` tries to access the internal registry.  A workaround for this is to delete (and re-generate) the secret:
E.g.:
```
oc delete secrets pipeline-dockercfg-hcbcv
```


