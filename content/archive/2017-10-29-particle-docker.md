---
title:  "Particle projects in docker containers"
draft: true
---

I've returned to [particle](http://particle.io) development again recently, and
found that managing node and its various dependencies is a little cumbersome, so
I decided to try installing the particle-cli tools inside a docker container.

Doing *all* my particle development inside a docker container would not have
been difficult, but would prevent me from having local files in a git repo. For
this reason, i wanted to create a particle dev image that could be used with
dockers "bind mounts", where a directory on the host system is mounted inside
the docker container.

{:.alert-info .alert}
Note that file permissions get tricky here. The userid inside the container is
different from the user that wrote the files in the host filesystem. You'll need
to set up docker "user namespaces" before you can follow the advice below. See
the [docker user namespace
guide](https://docs.docker.com/engine/security/userns-remap/) for help setting
this up.

Once 
