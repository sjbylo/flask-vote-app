# flask-vote-app
A sample web poll application written in Python (Flask).

Users will be prompted with a poll question and related options. They can vote preferred option(s) and see poll results as a chart. Poll results are then loaded into an internal DB based on sqlite. As alternative, the application can store poll results in an external MySQL database.

This application is intended for demo use only.

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
