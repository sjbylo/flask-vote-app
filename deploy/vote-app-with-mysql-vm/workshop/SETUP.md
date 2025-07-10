# Setup of the `Unifying Pods & VMs` Workshop

## Install one instance of Gitea for all workshop users

Use this [Gitea Operator](https://github.com/rhpds/gitea-operator) to provide a Gitea server so each user has access to their own repository and can make code changes.

Follow the instructions from the above guide, OR follow these below:

Log into the workshop cluster (do this for all workshop clusters if there are more than one) and run:

```
oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy
```

Wait for the deployment of the Operator.  Check the pods are running AND ready in the gitea-operator project:

```
oc get pods -n gitea-operator
```

Create the gitea namespace and set permissions (create read access to the gitea project so all users can find the Gitea Route):

```
oc new-project gitea
oc adm policy add-role-to-group view system:authenticated -n gitea
```

Create Gitea instance (important: check the changes needed below)

> Ensure giteaUserPassword (in the yaml below) is set to your preferred password, e.g. the password already provided by the lab environment.
> Create the correct number of users for your workshop.

Run this command to import the yaml into the gitea project:

```
oc apply -f - <<END
apiVersion: pfe.rhpds.com/v1
kind: Gitea
metadata:
  name: gitea
  namespace: gitea
spec:
  giteaSsl: false                     # Important, so ArgoCD can easily access the repos without a cert

  giteaAdminUser: admin
  giteaAdminPassword: "some-password"
#  giteaAdminPasswordLength: 6 
  giteaAdminEmail: email@address.com

  giteaDisableRegistration: true

  giteaCreateUsers: true
  giteaGenerateUserFormat: "user%d"
  giteaUserNumber: 3                  # <<== Ensure you provision enough users
  giteaUserPassword: password         # <<== Change the password here for all users

  giteaMigrateRepositories: true
  giteaRepositoriesList:
  - repo: https://github.com/sjbylo/flask-vote-app.git
    name: flask-vote-app
    private: false
END
```


## Example status of "Gitea" when complete. 

Check the status of the gitea instance and ensure it looks like the below `before starting the workshop!`

Note: "userSetupComplete: true" and "repoMigrationComplete: true"

```
status:
  adminPassword: "123456"
  adminSetupComplete: true
  conditions:
  - lastTransitionTime: "2025-06-18T01:32:34Z"
    message: ""
    reason: ""
    status: "False"
    type: Failure
  - lastTransitionTime: "2025-06-18T01:32:34Z"
    message: Last reconciliation succeeded
    reason: Successful
    status: "False"
    type: Successful
  - lastTransitionTime: "2025-06-18T01:26:02Z"
    message: Running reconciliation
    reason: Running
    status: "True"
    type: Running
  giteaHostname: gitea-gitea.apps.demo1.example.com
  giteaRoute: http://gitea-gitea.apps.demo1.example.com
  repoMigrationComplete: true                               # <<== wait for this to be true
  userPassword: password
  userSetupComplete: true
```

## (OPTIONAL) Run the setup script instead (experimental!) 

If there are several clusters to configure, use this script.

Set number of users in setup.sh script.  Get the api URLs of the workshop env. from demo.redhat.com.

```
./setup.sh admin-password user-password <path-to-file-with-all-api-urls>
```

