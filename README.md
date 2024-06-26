# flask-vote-app
A sample web poll application written in Python (Flask).

Users will be prompted with a poll question and related options. They can vote preferred option(s) and see poll results as a chart. Poll results are then loaded into an internal DB based on sqlite. As alternative, the application can store poll results in an external MySQL database.

The repo has been modified to make it easy to build and run on OpenShift.

The application has also been primed to be easily bound to RDS using the AWS's Service Catalog command line, svcat.  Here is an [example](https://github.com/sjbylo/lab-ocp4/blob/master/workshop/content/exercises/70-add-cloud-database.md#bind-to-the-database-service) of that.

This application is intended for demo use only.

[![Docker Repository on Quay](https://quay.io/repository/sjbylo/flask-vote-app/status "Docker Repository on Quay")](https://quay.io/repository/sjbylo/flask-vote-app)

## Local deployment

This application can be deployed locally. On linux, install git and clone the repository:

```
sudo yum install -y git
git clone https://github.com/sjbylo/flask-vote-app
cd flask-vote-app
```

Install the dependencies:

```
pip install flask
pip install flask-sqlalchemy
pip install mysqlclient
```

and start the application:

```
python app.py
Check if a poll already exists in the db
...
* Running on http://0.0.0.0:8080/ (Press CTRL+C to quit)
```

View the app in the browser.  The test script can also be used to test the vote app:

```
./test-vote-app http://localhost:8080
```

Poll question and options are loaded from a JSON file called ``seed_data.json`` under the ``./seeds`` directory. 
This file is filled with default values, change it before starting the application.

The DB data file is called ``app.db`` and is located under the ``./data`` directory. 
To use an external MySQL database, set the environment variables by editing the ``flask.rc`` file under the application directory.

```
nano flask.rc
export PS1='[\u(flask)]\> '
export ENDPOINT_ADDRESS=db
export PORT=3306
export DB_NAME=vote
export MASTER_USERNAME=voteuser
export MASTER_PASSWORD=password
export DB_TYPE=mysql
```

Make sure an external MySQL database server is running according to the parameters above.

Source the file and restart the application:

```
source flask.rc
python app.py
```

Cleanup:

```
rm -f data/app.db    # optionally remove the database 
```

## Docker deployment

The app can be run by pulling the image from quay.io and curling localhost:8080

```
docker run -d --rm -p 8080:8080 --name=vote-app quay.io/sjbylo/flask-vote-app
curl http://localhost:8080/
```

Stop the container with Ctrl+C

## Docker build and deployment

A Dockerfile is provided in the repository to build a docker image and run the application as linux container.

On Linux, install and start Docker:

```
sudo yum install -y docker
systemctl start docker
```

Install git and clone the repository:

```
sudo yum install -y git
git clone https://github.com/sjbylo/flask-vote-app
cd flask-vote-app
```

Build a Docker image:

```
docker build -t vote-app:latest .
docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
vote-app              latest              e6e0578f5f2d        2 minutes ago       695.4 MB
```

Start the container:

```
docker run -d -p 8080:8080 --name=vote-app vote-app:latest
```

Seed data directory, containing the seed data file ``seed_data.json``, can be mounted as an external volume under the host ``/mnt`` directory:

```
cp flask-vote-app/seeds/seed_data.json /mnt
docker run -d -p 8080:8080 -v /mnt:/app/seeds --name=vote-app vote-app:latest
```

An external MySQL database can be used instead of the internal sqlite by setting the desired env variables:

```
docker run -e ENDPOINT_ADDRESS=db \
           -e PORT=3306 \
           -e DB_NAME=vote \
           -e MASTER_USERNAME=voteuser \
           -e MASTER_PASSWORD=password \
           -e DB_TYPE=mysql \
           -d -p 8080:8080  --name=vote-app vote-app:latest
```

Cleanup:

```
docker stop vote-app && docker rm vote-app
```

## Install the app onto OpenShift

Build and launch the app:

```
oc new-app python~https://github.com/sjbylo/flask-vote-app.git --name vote-app
```

As an alternative to the above build, pull the latest image from quay.io registry:

```
oc new-app --docker-image=quay.io/sjbylo/flask-vote-app:latest --name vote-app
```

Expose the app to the external network:

```
oc expose svc vote-app
```

Start a database (optional, if scale-out is required):

```
oc new-app --name db mysql:5.7 -e MYSQL_USER=user -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=vote
```

Connect the app to the DB:

```
oc set env dc vote-app \
   ENDPOINT_ADDRESS=db \
   PORT=3306 \
   DB_NAME=vote \
   MASTER_USERNAME=user \
   MASTER_PASSWORD=password \
   DB_TYPE=mysql
```

## Develop and quickly build and test the app from your local directory

To easily develop this application, we can make changes to the local files and then re-build the app by uploading the changes to a new build pod. 

To do this we create a 'binary' build.  Binary is referring to the way the local directory is sent or "streamed" to the build pod using tar. 

```
oc new-build python --name vote-app --binary
```

Start the build.  This will upload the app code from the current working dir:

```
oc start-build vote-app --from-dir=. --follow
```

Wait for the build to complete. Launch the app:

```
oc new-app vote-app
```

Expose the app to the external network:

```
oc expose svc vote-app
```

Test the app, e.g. on mac:

```
VOTE_APP=`oc get route vote-app --template='{{.spec.host}}'`
./test-vote-app $VOTE_APP 
open http://$VOTE_APP/
```

Now, make changes to the local file(s) and re-build the app.
To re-build the app on the server, run the above "oc start-build" command again. 

## Expose the database to the external network (optional) 

If you need to allow external ingress connections to the database, for example on AWS or other public cloud providers, you can try this:

```
oc apply -f - <<END
apiVersion: v1
kind: Service
metadata:
  name: db-ext
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  selector:
    deployment: db
  type: LoadBalancer
END
```

or run this command to do the same thing:

```
oc expose deploy db --port=3306 --name=db-ext --type=LoadBalancer
```

After the service has been created and the actual load balancer (e.g. ELB in AWS) has been provisioned (including DNS), run something like this:

```
oc get svc
NAME TYPE         CLUSTER-IP     EXTERNAL-IP                                                                  PORT(S)          
db   LoadBalancer 172.30.193.154 a3faeda4dfe564b05ad14cd157bd2450-1000531162.ap-southeast-1.elb.amazonaws.com 3306:30392/TCP 

mysql -u user -ppassword -h a3faeda4dfe564b05ad14cd157bd2450-1000531162.ap-southeast-1.elb.amazonaws.com
Welcome to the MySQL monitor.  Commands end with ; or \g.
...
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| vote               |
+--------------------+
2 rows in set (0.01 sec)
```

## Open a dev session with the online Eclipese Che IDE

You can start a workspace on demand by opening the devfile.yaml file in Eclipse Che. 

As an example, create an account at https://che.openshift.io/ and then open this URL:

https://che.openshift.io/f?url=https://github.com/sjbylo/flask-vote-app


## Tekton CI/CD Pipeline on OpenShift 4.4

This pipeline will provision a MySQL server in Azure, build the vote app, launch the app and connect it to the MySQL database. 
For this pipeline to work fist set up the [Azure Servie Operator](https://github.com/sjbylo/lab-azure-service-operator) on OpenShift.

Create the Tekton Pipline in a new project called vote-app: 
```
oc new-project vote-app
cd pipeline
oc create -f .
```

To trigger the CI/CD pipeline either go to the OpenShift Console and start the pipeline or run the following command.  tkn cli can be downloaded from the OpenShift Console. 
```
tkn pipeline start build-and-deploy -r git-repo=vote-app-source -r image=vote-app-image -p deployment-name=vote-app
```






