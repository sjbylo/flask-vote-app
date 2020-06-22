# DevOps Ramp Up

This is mainly an excuse to learn Azure as well as work on DevOps-y best practices.  I originally forked this repo from the `flask-vote-app` in an effort to grab a simple and reliable service that could easily be deployed.  I walked through various ways to deploy locally, in cloud, with automated tooling, and (eventually), automatically.

This README is for how to deploy this app locally.  Once that's mastered, pop over to the `ops` folder to see the real meat of the development.

# Ops

See `ops/README.md` for more...

# Local

### flask-vote-app
A sample web poll application written in Python (Flask).

Users will be prompted with a poll question and related options. They can vote preferred option(s) and see poll results as a chart. Poll results are then loaded into an internal DB based on sqlite. As alternative, the application can store poll results in an external MySQL database.

This application is intended for demo use only.

#### Deployment

Install the dependencies:

```
$ pip3 install -r requirements.txt
```

start the application:

```
$ python3 app.py
```

View the app in the browser. 

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
$ source flask.rc
(flask) $ python3 app.py
```

Cleanup:

```
rm -f data/app.db    # optionally remove the database 
```
