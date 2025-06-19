# Setup of the Virt + GitOps workshop labs

## Install of Gitea for each user

Use this [Gitea Operator](https://github.com/rhpds/gitea-operator) to provide a Gitea server so each user has access to their own repository and can make code changes.

Follow the instructions from the above guide, or follow these below:

```
oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy
```

Wait for deployment of the Operator and then create the Gitea instance.
Ensure giteaUserPassword is set to your prefered password, eg the password already provided by the lab environment.

```
apiVersion: v1
kind: Namespace
metadata:
  name: gitea
---
apiVersion: pfe.rhpds.com/v1
kind: Gitea
metadata:
  name: gitea
  namespace: gitea
spec:
  giteaSsl: false                     # Important, so ArgoCD can easily access the repos

  giteaAdminUser: admin
  giteaAdminPassword: "some-password"
#  giteaAdminPasswordLength: 6 
  giteaAdminEmail: email@address.com

  giteaDisableRegistration: true

  giteaCreateUsers: true
  giteaGenerateUserFormat: "user%d"
  giteaUserNumber: 30                 # <<== Ensure you provision enough users
  giteaUserPassword: password         # <<== Change the password here for all users

  giteaMigrateRepositories: true
  giteaRepositoriesList:
  - repo: https://github.com/sjbylo/flask-vote-app.git
    name: flask-vote-app
    private: false
```

## Create read access to the gitea project for all users

Users need to find the Route hostname to use to access their repos.

```
oc adm policy add-role-to-group view system:authenticated -n gitea
```


## Example status of "Gitea" when complate. 

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
  repoMigrationComplete: true
  userPassword: password
  userSetupComplete: true
```

## (OPTIONAL) Run the setup script instead

If there are several clusters to configure, use this script.

Set number of users in setup.sh script.

```
./setup.sh admin-password user-password <path-to-file-with-all-api-urls>
```

