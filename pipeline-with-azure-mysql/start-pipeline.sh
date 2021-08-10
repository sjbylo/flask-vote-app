P=`oc project -q`

tkn pipeline start vote-app-build-and-deploy \
       -w name=shared-workspace,claimName=source-pvc \
       -p deployment-name=vote-app \
       -p git-url=https://github.com/sjbylo/flask-vote-app.git \
       -p IMAGE=image-registry.openshift-image-registry.svc:5000/$P/vote-app \
       --showlog 

