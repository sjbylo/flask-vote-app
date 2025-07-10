#!/bin/bash -e

apw=$1; shift
upw=$1; shift
ucnt=3
input=$1; shift

echo admin pw=$apw
echo user pw=$upw
echo input=$input

urls=$(grep -o "https://api.*" $input | sort | uniq)
logins=$(grep -o "oc login.*https://api.*" $input | sort | uniq)

urls_arr=()
while IFS= read -r line; do
  urls_arr+=("$line")
done <<< "$urls"
for i in "${urls_arr[@]}"; do
  echo ">$i<"
done

logins_arr=()
while IFS= read -r line; do
  logins_arr+=("$line")
done <<< "$logins"
for i in "${logins_arr[@]}"; do
  echo ">$i<"
done

echo

echo -n "Hit enter: "
read yn

set -x

i=0

for i in "${logins_arr[@]}"; do
	echo ">$i<"
	echo Install Op. for cluster $i

	oc login -u admin -p ${apws[$i]} $url --insecure-skip-tls-verify
	oc apply -k https://github.com/rhpds/gitea-operator/OLMDeploy
done

echo "$logins" | while read l
do
	echo Install Op. for cluster $l

	eval 

	echo "$l"
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
  giteaUserNumber: $ucnt
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

