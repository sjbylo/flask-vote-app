#!/bin/bash -e

#apw=$1; shift
upw=$1; shift
input=$1; shift

#echo admin pw=$apw
echo user pw=$upw
echo input=$input

url=$(grep -o "https://api.*" $input | sort | uniq)

#apws=$(grep -o "^password: .*" $input | sed "s/password: //g" | uniq) 
##readarray -t apws < <(grep -o "admin .* password: .*" $input | sed "s/admin password: //g" | uniq)  

#User admin with password MjVXjtNklXw2Rcv6

apws=()
while IFS= read -r line; do
  apws+=("$line")
done < <(grep "^User admin with password " $input | awk '{print $5}' | uniq)

#grep "User admin with password" yourfile.txt | awk '{print $5}'


#sbylo-mac:workshop steve$ grep -o -e "https://api\..*" -e "^password: .*" tt | sed "s/password: //g" | sort |uniq
#https://api.cluster-9mzvv.dynamic.redhatworkshops.io:6443

echo urls="${urls[@]}"
echo apws="${apws[@]}"

echo
for f in ${urls[@]}
do
	echo $f
done
echo
for f in ${apws[@]}
do
	echo $f
done

echo ${apws[0]}
echo ${apws[1]}

i=0
for url in ${urls[@]}
do
	echo ${apws[$i]}
	let i=$i+1
done

echo -n "Hit enter: "
read yn

set -x

i=0
for url in ${urls[@]}
do
	echo Install Op. cluster $url

	echo "oc login -u admin -p ${apws[$i]} $url --insecure-skip-tls-verify"
	read yn
	oc login -u admin -p ${apws[$i]} $url --insecure-skip-tls-verify
	sleep 1

	oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy

	let i=$i+1
done

exit 

i=0
for url in ${urls[@]}
do
	echo Add Gitea for $url

	oc login -u admin -p ${apws[$i]} $url --insecure-skip-tls-verify

	until oc get po -n gitea-operator | grep gitea-operator-controller-manager.*2/2
	do
		sleep 10
	done

	sleep 5

	oc apply -f - <<END
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
  giteaSsl: false

  giteaAdminUser: admin
  giteaAdminPassword: "$apw"
#  giteaAdminPasswordLength: 6 
  giteaAdminEmail: email@address.com

  giteaDisableRegistration: true

  giteaCreateUsers: true
  giteaGenerateUserFormat: "user%d"
  giteaUserNumber: 30
  giteaUserPassword: $upw

  giteaMigrateRepositories: true
  giteaRepositoriesList:
  - repo: https://github.com/sjbylo/flask-vote-app.git
    name: flask-vote-app
    private: false
END

	oc adm policy add-role-to-group view system:authenticated -n gitea

	let i=$i+1
done


for url in ${urls[@]}
do
	echo Checking cluster $url

	oc login -u admin -p $apw $url --insecure-skip-tls-verify
	sleep 1

	until oc get gitea -n gitea -o yaml | grep "repoMigrationComplete: true"
	do
		sleep 10
	done

	set +x
	echo ==========================================================================================
	echo $url done
	echo ==========================================================================================
	echo
	set -x
done


for url in $urls
do
	echo Checking repo $url

	oc login -u admin -p $apw $url --insecure-skip-tls-verify

	u=$(oc get gitea -n gitea -o yaml | grep giteaRoute | grep -o http.*)/user1/flask-vote-app
	curl -IL $u
done

set +x

echo
echo ALL DONE

