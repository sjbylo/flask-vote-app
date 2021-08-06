# Any of these base images should work...
# This open registry may go away!
FROM registry.access.redhat.com/ubi8/python-38:1-9


# Authenticated registry:
#FROM registry.redhat.io/ubi8/python-38         

# Usually docker hub:
#FROM python:3.8

LABEL Version 1.0

MAINTAINER kalise <https://github.com/kalise/>

# By default, the app uses an internal sqlite db
# Use env variables to connect to an external SQL engine, e.g. MySQL
# ENV ENDPOINT_ADDRESS "db"
# ENV PORT "3306"
# ENV DB_NAME "vote"
# ENV MASTER_USERNAME "voteuser"
# ENV MASTER_PASSWORD "password"
# ENV DB_TYPE "mysql"

# Set the application directory
WORKDIR /app

# Install requirements.txt
ADD requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# Copy code from the current folder to /app inside the container
ADD . /app

USER root

RUN chown -R 1001 /app && chmod -R g=u /app && chgrp -R 0 /app

# Mount external volumes for logs and data
#VOLUME ["/app/data", "/app/seeds", "/app/logs"]

USER 1001

# Expose the port server listen to
EXPOSE 8080

# Define command to be run when launching the container
CMD ["python", "app.py"]
# test change

