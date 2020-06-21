# How this Happened

I am cataloging the various steps that this "service" took to become "scalable".  I'll include shitty hand-drawn architecture diagrams that will hopefully help illustrate the point.

## 1: Initial Deployment

For this iteration, I'm doing something dumb.  I am deploying the entire stack on a single virtual azure machine.  Although this is not in any way "scalable" or "resilient", it will give a good example for how to set up many of the initial infrastructural components that are necessary for even running a deployment.  This process will allow me to deploy using solely the command line.  In future iterations, I will break out system components in such a way as to make the architecture scalable, then add resiliency and all of the other goodies that could be expected from a web service.

#### 1.1: Create working App

After forking a known good working "web service" with a front end, a webserver, and a backend, I stripped out all unnecessary functionality.  The service is designed as such:

![Arch Diagram 1](./img/01.jpeg)

This service is deployed manually on your local machine and requires a bit of setup to work.  For one, you have to configure a MySQL database such that the parameters defined in the `flask.rc` file.  You'll need a user with the correct permissions.  In order to deploy the app locally, once the db is configured, install dependencies using `pip install -r requirements.txt`, add env vars of `flask.rc` using `source ./flask.rc`, and deploy using `python app.py`.

#### 1.2 Create the Necessary Users and Groundwork on Azure

While AWS has a concept of roles and policies to manage RBAC, Azure uses a hierarchical model where resources are organized into `Management Groups > Subscriptions > Resources Groups > Resources`.  For the purposes here, I'm going to assume that I'm creating a application that would fall under a resource group that uses resources.  So I'm going to skip creating infrastructure for a management group or a subscription.

##### 1.2.1 Resource Group

Within the Azure Portal, I provisioned a Resource Group using the wizard:

![Azure Resource Group](./img/02.jpg)

##### 1.2.2 Virtual Machine + Others

I provisioned a Linux VM using Ubuntu 18.04 and the Azure "B1LS" tier machine.  I kept most of the default settings, but one critical setting changed was networking.  I created a new security group which allowed incoming traffic on both ports 22 and 8080 such that the app could be accessed from the public internet and the instance could be SSH'd into.  A New SSH key was created.  When provisioning via a bot user as I will eventually do, there will have to be an existing bot SSH key that is used for provisioning, but for now, I'm likely going to need to do some troubleshooting from the command line.

##### 1.2.3 MySQL

Create a managed MySQL instance from the Azure portal.  It'll ask for configuration like username and password, be sure to write these down as you'll need them in your flask.rc.  I only used the most basic tier to stay within cost limits (~30$/mo, which is within my trial credits).  This is done using the Azure for MySQL managed solution.  When setting up the DB, I had to write down the hostname of the MySQL Instance, as well as the Username and Password that I created.  

I had to remember to add the IP address of the VM that I created to the MySQL instance firewall rules.  I also had to manually create the database that I wanted to use as well as grant privileges to the username who I created.

`CREATE DATABASE PollingAppDb;`

`GRANT ALL PRIVILEGES ON PollingAppDb.* TO '<user>'@'<host>';`

##### 1.3 Install and Run Service

From here I SSH'd into the instance using the key pair that was created and the public IP address provisioned.  I used git to clone a known good version of the service from github and set it up in a local directory.  In order to install dependencies, I had to manually install pip3 and libmysqlclient-dev with `sudo apt update && sudo apt install libmysqlclient-dev python3-pip -y`.  This is already a pain in the ass.  Wouldn't it be nice if there was a way that software could provision all of this for me...?

At this point, I have a running and publicly accessible website that is attached to the MySQL backend.  I have an open public IP that can be accessed through the 8080 port, and the front end can talk to the backend!  Scalability achieved!  Here's what the architecture looks like at this point:

![First Cloud Arch](./img/04.jpeg)

And a screenshot of the website in action:

![Bad First Deploy](./img/03.jpg)

But can we do better...

## 2: Repeatable Infrastructure
