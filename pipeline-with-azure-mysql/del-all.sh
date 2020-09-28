[ -s .saved_project ] && P=`cat .saved_project`

oc delete  mysqlservers,mysqlfirewallrule,mysqluser,mysqldatabase --all -n $P
oc delete  pipeline,pipelinerun,task,taskrun,po,pipelineresource --all -n $P
#oc delete  deploy,po,svc,route,is --all -n $P
oc delete deploy,po,svc,route,is -l app=vote-app
#oc delete  all --all  -n $P

rm -f .saved_project
