# How this Happened

I am cataloging the various steps that this "service" took to become "scalable".  I'll include shitty hand-drawn architecture diagrams that will hopefully help illustrate the point.

## 1: Initial Deployment

For this iteration, I'm doing something dumb.  I am deploying the entire stack on a single virtual azure machine.  Although this is not in any way "scalable" or "resilient", it will give a good example for how to set up many of the initial infrastructural components that are necessary for even running a deployment.  This process will allow me to deploy using solely the command line.  In future iterations, I will break out system components in such a way as to make the architecture scalable, then add resiliency and all of the other goodies that could be expected from a web service.

#### 1.1: Create working App

After forking a known good working "web service" with a front end, a webserver, and a backend, I stripped out all unnecessary functionality.  The service is designed as such:

** architecture diagram **

