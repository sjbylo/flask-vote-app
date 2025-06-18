# WORK IN PROGRESS
to do:
- Include both a manual sync and auto-sync scenario.
- Add a Git change mid-workshop and show ArgoCD’s detection of drift.

# Workshop - Mixed Pod + VM OpenShift Virtualization GitOps Demo

GitOps is a way to manage infrastructure and applications using Git as the single source of truth.
It automates deployment by syncing the desired state in Git with the live environment.
Every change is tracked in Git, providing a full audit trail for transparency and accountability.

Use OpenShift Virtualization & GitOps to deploy a demo vote application pod and a MySQL VM.

You can learn more about GitOps from this [GitOps Workshop Guide](https://openshiftdemos.github.io/openshift-gitops-workshop/openshift-gitops-workshop/index.html).

Once the application is deployed this is what you will see.

<img src="./images/vote-app-plus-vm-demo.png" alt="This is what it looks like" width="500">

We will use the OpenShift GitOps Operator (based on the ArgoCD project) to implement GitOps and deploy our demo application. 

## Create a new Project 

Create a new project for yourself to work in and remember the project name.  Use a unique name, e.g. gitops-user1

You can do this in the OpenShift Console under `Home -> Projects -> Create Project` or from the command line with "oc new-project my-project".

You will use this project for all further activities.


## Provision your own instance of OpenShift GitOps (ArgoCD)

First, you will provision your own instance of ArgoCD into your OpenShift namespace.

Add the following ArgoCD resource into your namespace.  There are many ways to do this, e.g. via the OpenShift Console or via the command line.

Don't forget to change the `YOUR-OPENSHIFT-NAMESPACE` in the yaml code to match your OpenShift namespace. 

```
apiVersion: argoproj.io/v1beta1
kind: ArgoCD
metadata:
  name: argocd
  namespace: YOUR-OPENSHIFT-NAMESPACE
spec:
  controller:
    processors: {}
    resources:
      limits:
        cpu: "2"
        memory: 2Gi
      requests:
        cpu: 250m
        memory: 1Gi
    sharding: {}
  grafana:
    enabled: false
    ingress:
      enabled: false
    route:
      enabled: false
  ha:
    enabled: false
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  initialSSHKnownHosts: {}
  monitoring:
    enabled: false
  notifications:
    enabled: false
  prometheus:
    enabled: false
    ingress:
      enabled: false
    route:
      enabled: false
  rbac:
    defaultPolicy: ""
    policy: |
      g, system:authenticated, role:admin
      g, system:cluster-admins, role:admin
    scopes: '[groups, users]'
  redis:
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  repo:
    resources:
      limits:
        cpu: "1"
        memory: 1Gi
      requests:
        cpu: 250m
        memory: 256Mi
  resourceExclusions: "- apiGroups:\n  - tekton.dev\n  clusters:\n  - '*'\n  kinds:\n
    \ - TaskRun\n  - PipelineRun        \n"
  server:
    autoscale:
      enabled: false
    grpc:
      ingress:
        enabled: false
    ingress:
      enabled: false
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 125m
        memory: 128Mi
    route:
      enabled: true
    service:
      type: ""
  sso:
    dex:
      openShiftOAuth: true
      resources:
        limits:
          cpu: 500m
          memory: 256Mi
        requests:
          cpu: 250m
          memory: 128Mi
    provider: dex
  tls:
    ca: {}
```

Wait 5 mins for all the pods in your namespace to be Running and Ready, i.e. (1/1). 

Find the Route that was created and access it to open the ArgoCD UI at the login page.
Log into ArgoCD with your usual OpenShift credentials (use the `LOG IN VIA OPENSHIFT` button) and, on the next page, allow the `access permissions`.

Here is one way to find the ArgoCD Route.  The other way is to look at the main menu on the left under Networking -> Routes. 

```
oc get route -n YOUR-NAMESPACE your-argo-server -o jsonpath='{.spec.host}{"\n"}'
```

You will now see the ArgoCD UI in your browser.

Create the vote-app Application using the following Application resource (note, this will only work for clusters with direct access to the Internet).


## Know your Git Repo URL

Log into Gitea via its Route which you will find in your namespace (Menu -> Networking -> Routes).  
Note that your repository (source copy of the original flask-vote-app app) and fetch the repo URL.  

Your Git repo URL will look something like this:

```
http://gitea-with-repositories-gitea.apps.sandbox.openshift.com/user1/flask-vote-app.git
```

Once you log in, you will see your code repo with the name, e.g. "user1/flask-vote-app"

Look into the folder "deploy/vote-app-with-mysql-vm/direct" and open the file `vote-app-mysql-vm-all-in-one.yaml`.

In the file, you will see all the Kubernetes resources that are needed to deploy the application. 
Note the following:
  - `kind: Deployment` (name: vote-app) - this is the configuration that will provision the vote-app in a pod
  - `kind: Service` (name: db) - this is configuration that will enable the pod to access the MySQL VM via the pod network
  - `kind: VirtualMachine` - this is the configuration that will provision the MySQL VM
  - `kind: Route` - this is the configuration that will provide north-south ingress into the vote-app application


Later on in the workshop you will make changes to the code and see the changes take effect in OpenShift. 


## Create the Demo Application

In Argo CD, a managed set of Kubernetes manifests is called an Application. 
To enable Argo CD to deploy these manifests to your cluster, you need to define them using an `Application Custom Resource` (CR).

Let’s take a look at the Application manifest used for this deployment and break it down:


```
kind: Application
metadata:
  name: vote-app
  namespace: YOUR-OPENSHIFT-NAMESPACE             # <<== Add your namespace here
spec:
  destination:
    namespace: YOUR-OPENSHIFT-NAMESPACE           # <<== Add your namespace here
    server: https://kubernetes.default.svc

  project: default

  source:
    path: deploy/vote-app-with-mysql-vm/direct
    repoURL: http://HOST/YOUR-REPO-PATH.git       # <<== add your repo URL here
    targetRevision: HEAD

#  syncPolicy:
#    automated:
#      prune: true
#      selfHeal: false
```

- `destination`: describes into which cluster and namespace to apply the yaml resources (using the locally-resolvable URL for the cluster)
- `project default`: is an ArgoCD concept and has nothing to do with OpenShift projects
- `source`: describes from which git repository and the directory path to fetch the yaml resources
- `prune`: resources, that have been removed from the Git repo, will be automatically pruned
- `selfHeal` false: manual changes made to the kubernetes resources, e.g. using oc or kubectl, will not be "healed"

Create the above Application by:

- Clicking on the "CREATE APPLICATION" button in the ArgoCD UI
- Click on the "EDIT AS YAML" button
- Copy and paste and then
- `Edit the yaml` as indicated above
- Click SAVE and then
- Click the CREATE button

`Be sure to change the values in the below Application manifest: both namespaces & repoURL`

Note that after the VM status is `Running` it will still `take up to 5 mins` for the MySQL VM to launch and run its `cloud-init` script to install, configure and run MySQL, 
after which the vote application will connect to the database and be ready to use.  

Using the Virtualization menu item, find and then log into the MySQL VM's Console and check the output of the cloud-init script.  
See the log file at /var/log/cloud-init-output.log.

Also, verify that MySQL is running in the VM with "ps -ef | grep -i mysql".  Bonus activity, if you know how, connect to MySQL and view the database contents.


## Self Healing

Notice that we set the following in the above yaml resource.  We set the application to NOT `self heal`.  Let's test this now. 

```
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: false 
```

Since `selfHeal` was set to false, we will delete one of the kubernetes resources of the application.

Now, delete the vote-app route in your namespace. 

What happened? 

It does not get re-created automatically!  Why not? 

Set selfHeal to "auto" in the ArgoCD UI.  Go to the Application, click `Details` and make the change for the vote-app to self heal. 
Save the changes.   

Make a change in OpenShift and see it "heals":


## Clean up 

Now delete the application.

On the ArgoCD UI, drill down into your Application tile, click on delete and watch all the resources be removed. 

## The End

That is the end of the Virt + GitOps workshop.  You have learned how to configure OpenShift GitOps (ArgoCD) and use it to provision and manage application 
in OpenShift, via Git.


