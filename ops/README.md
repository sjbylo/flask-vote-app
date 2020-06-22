# Deployment and Operationalization

This project is mainly intended to learn the Azure platform as well as designing a scalable system from the ground up.  I am working off of a fork of the [flask voting app](https://github.com/sjbylo/flask-vote-app) created by `pyfrog` and `sjbylo`.  

## Overview

In order to run this web app in Azure Cloud, make sure you can communicate with the [Azure Portal](https://portal.azure.com/#home) via the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).  If this is your first time working in Azure, [make sure to follow the setup instructions to get things going.](https://azure.microsoft.com/en-us/get-started/).  

Once the CLI is installed, if you can run:

```
$ az login
$ az account list
```
without error, you should be good to go.

### Important Note

This is a living document!  As I create more and more infrastructure, this doc will change.  To see the entirety of the process from deploying locally, to cloud deployment manually, to fully automated (eta ... sometime?) deployment, and beyond, see the `HISTORY.md` document.

### Setup

Create a new SSH keypair:

`$ ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure/id_rsa`

Create the necessary environment files according to your own specifications  Hopefully they are self-explanatory:

- terraform/prod.tfvars
- ansible/vars/vars.yaml
- ansible/roles/webserver/vars/env.yaml

There is more guidance on how to create these files in the `HISTORY.md` document.

### Deployment

To deploy this project, create the necessary environment variable files, and run:

```
$ cd ops/terraform
$ terraform init  // only necessary the first time
$ terraform apply --var-file=prod.tfvars

** take a quick break to edit ansible/hosts file with the newly created VM's IP address**

$ cd ../ansible
$ ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts --private-key ~/.ssh/azure/id_rsa main.yaml
```

### Cleanup:

```
$ cd ops/terraform
$ terraform destroy --var-file=prod.tfvars
```
