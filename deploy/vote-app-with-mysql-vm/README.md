# Deploy vote-app with a VM running Centos8 and MySQL Community 

This yaml should work out-of-the-box as long as the "centos-stream8" DataSource exists in the "openshift-virtualization-os-images" namespace. 

If not, then .... 
... this requires a root disk "source" PVC be created.
Use the source creation feature (e.g. download from URL) or the PVC "With Data upload" features to create it.
Upload an image from https://cloud.centos.org/centos/
e.g.
https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2
or something newer.


```
        source:
          pvc:
            name: centos8
            namespace: openshift-virtualization-os-images
```

Then create the application:

```
oc apply -f vote-app-mysql-vm-all-in-one.yaml
```

Note that it will take up to 5 mins for the MySQL VM to launch and run its cloud-init script to install, configure and run MySQL. 

Tested with Centos8.


