# sonatype/docker-nexus

A Docker image for Sonatype Nexus OSS with the Oracle JDK.

To run (if port 8081 is open on your host):

```
# docker run -d -p 8081:8081 --name nexus <username>/nexus
```

or to assign a random port that maps to port 8081 on the container:

```
# docker run -d -p 8081 --name nexus <username>/nexus
```

To determine the port that the container is listening on:

```
# docker ps nexus
```

To test:

```
$ curl http://localhost:8081/service/local/status
```

To build:

Copy the sources down and do the build-

```
# docker build --rm=true --tag=<username>/nexus .
```


## Notes

* Default credentials are: `admin` / `admin123`

* It can take some time (2-3 minutes) for the service to launch in a
new container.  You can tail the log to determine once Nexus is ready:

```
$ docker logs -f nexus
```

* Installation of Nexus is to `/opt/sonatype/nexus`.  Notably:
  `/opt/sonatype/nexus/conf/nexus.properties` is the properties file.
  Parameters (`nexus-work` and `nexus-webapp-context-path`) definied
  here are overridden in the JVM invocation.

* A persistent directory, `/sonatype-work`, is used for configuration,
logs, and storage. This directory needs to be writable by the Nexus
process, which runs as UID 200.

* Three environment variables can be used to control the JVM.

  * `MAX_HEAP`, passed as -Xmx.  Defaults to `1g`.
  * `MIN_HEAP`, passed as -Xms.  Defaults to `256m`.
  * `JAVA_OPTS`.  Additional options can be passed to the JVM via this variable.
  Default: `-server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true`.

  These can be used supplied at runtime to control the JVM:

  ```
  $ docker run -d -p 8081:8081 --name nexus -e MAX_HEAP=768m sonatype/nexus
  ```


### Persistent Data

There are two general approaches to handling persistent
storage requirements with Docker. See [Managing Data in
Containers](https://docs.docker.com/userguide/dockervolumes/) for
additional information.

  1. *Use a data volume container*.  Since data volumes are persistent
  until no containers use them, a container can created specifically for 
  this purpose.  This is the recommended approach.  

  ```
  $ docker run -d --name nexus-data sonatype/nexus echo "data-only container for Nexus"
  $ docker run -d -p 8081:8081 --name nexus --volumes-from nexus-data sonatype/nexus
  ```

  2. *Mount a host directory as the volume*.  This is not portable, as it
  relies on the directory existing with correct permissions on the host.
  However it can be useful in certain situations where this volume needs
  to be assigned to certain underlying storage.  

  ```
  $ mkdir /some/dir/nexus-data && chown -R 200 /some/dir/nexus-data
  $ docker run -d -p 8081:8081 --name nexus -v /some/dir/nexus-data:/sonatype-work sonatype/nexus
  ```

