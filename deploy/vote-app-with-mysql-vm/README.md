# Deploy vote-app with a VM running Centos and MySQL Community 

This yaml requires a root disk "source" PVC be created.
Use the source creation feature (e.g. download from URL) or the PVC "With Data upload" features to create it.
Upload an image from https://cloud.centos.org/centos/
e.g.
https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2


```
        source:
          pvc:
            name: centos8
            namespace: openshift-virtualization-os-images
```

Then create the VM using the Centos8 Termplate and specify the source PVC you just created. 
