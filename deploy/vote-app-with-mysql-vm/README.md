# Mixed Pod + VM demo. 

Deploy vote-app + MySQL with a VM running either RHEL or Centos-Stream9.

This yaml should work out-of-the-box as long as the "rhel9" or "centos-stream9" DataSource exists in the "openshift-virtualization-os-images" namespace which is normally created after a default installation of OpenShift Virtualization.   If not, then ... see below "Create a DataSource". 

<img src="./images/vote-app-plus-vm-demo.png" alt="This is what it looks like" width="500">

Create the application:

```
oc new-project myproj
oc apply -f vote-app-mysql-vm-all-in-one.yaml
```

If OCP is behind a proxy, use the following. Be sure to edit the 3 "*_proxy" vars to suit your environment:
```
oc new-project myproj
oc apply -f vote-app-mysql-vm-all-in-one-with-proxy.yaml
```

Note that it will take up to 5 mins for the MySQL VM to launch and run its cloud-init script to install, configure and run MySQL, after which the application will come up and be ready to use.  See the log file /var/log/cloud-init-output.log to troubleshoot. 

Tested with Centos-Stream9 and RHEL9.


## Create a DataSource

Use the [source creation feature](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/virtualization/virtual-machine-templates#virt-creating-and-using-boot-sources) when creating a PVC (e.g. download from URL) or "With Data upload" features to create it.

Download an image from https://cloud.centos.org/centos/
e.g.
https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2
or something newer and then create the boot source from the image.

Them add this yaml snip-it to your VM definition: 

```
        source:
          pvc:
            name: centos-stream9
            namespace: openshift-virtualization-os-images
```


