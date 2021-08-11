# Install Gitea 

First get access to the operator and then install the Operator via the Console:

```
oc apply -f https://raw.githubusercontent.com/redhat-gpte-devopsautomation/gitea-operator/master/catalog_source.yaml 
```

Apply the CR to provision Gitea into the gitea project:

```
oc apply -f .
```

These instructions are from here:

https://github.com/redhat-gpte-devopsautomation/gitea-operator
https://gitea.io/en-us/
