# Demo Pipeline using roxctl 

This demo shows the use of roxctl in a Tekton Pipeline.  Is shows scanning/checking a freshly built 
image for CVEs and checking the app deployment manifest for bad practices. 

The demo uses a repo with a simple python application.
The master branch causes no failures but the "cve" branch causes roxctl checks to fail.

The branch can be chosen when starting the pipeline.


## Set up the Demo

First, spin up a demo cluster for Advanced Cluster Security (ACS) in RHPDS (warning, internal tool).

If you're really impatient, you can try to run the "./go.sh" script.

Following are the manual steps.

## Set up as cluster-admin 

Create a demo project

```
oc new-project acs-pipeline-demo
```

Copy the provided ACS demo secret over (or export credentials from the ACS Console) 

```
oc get secret roxsecrets -o yaml -n stackrox-pipeline-demo | grep -v '^\s*namespace:\s' | oc create -f -
```

Some of the provided demo cluster tasks have been modified so add them:

```
oc create -f clustertasks 
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

## Troubleshooting

Sometimes a 401 error can be seen when `roxctl` tries to access the internal registry.  A workaround for this is to delete (and re-generate) the secret:
E.g.:
```
oc delete secrets pipeline-dockercfg-hcbcv
```


