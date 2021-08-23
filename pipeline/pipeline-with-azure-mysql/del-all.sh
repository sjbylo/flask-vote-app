oc delete  mysqlservers,mysqlfirewallrule,mysqluser,mysqldatabase --all 
oc delete  pipeline,pipelinerun,task,taskrun,po,pipelineresource --all 
#oc delete  deploy,po,svc,route,is --all 
oc delete deploy,po,svc,route,is -l app=vote-app
#oc delete  all --all  

