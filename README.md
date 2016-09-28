# sonatype/docker-nexus

Docker images for Sonatype Nexus Repository Manager 2 with OpenJDK and
Red Hat Enterprise Linux 7. Make to run on the Red Hat OpenShift Container
Platform.

# Building in OpenShift

First login in to OpenShift and clone the project and OpenShift branch

```
git clone -b ose https://github.com/sonatype/docker-nexus.git
```

## Quickstart

If you would like to run the init.sh script provided in the repository,
it will create an OpenShift project named `nexus` within your OpenShift
instance which has pre-made templates for either Nexus OSS and Nexus Pro.
The script takes a single argument for an `oss` or `pro` installation.

```
cd docker-nexus/
./init.sh pro
```

After using the init.sh script, browse to the OpenShift console and login.
In the nexus project, click `Add to Project` and search for Nexus. Click
create and configure to create a Nexus service. Wait until the service has
been created and the deployment is successful. A Nexus instance should now
be available on the configured service.
