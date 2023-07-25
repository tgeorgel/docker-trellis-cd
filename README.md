## tgeorgel/docker-trellis-cd

This is a fork of `zessx/trellis-cd`, updated for Ubuntu 20.04, Ansible 2.9 and newer node images.

Provides a deploy image for Trellis with:

 - Ubuntu
 - Ansible
 - Node.js
 - Yarn

## Releases
 - 1.0-node*: Ubuntu 18.04 / Ansible 2.7 => see `zessx/trellis-cd` image
 - 1.2-node*: Ubuntu 18.04 / Ansible 2.9 => see `zessx/trellis-cd` image
 - 1.3-node*: Ubuntu 20.04 / Ansible 2.9


## Adding image
docker build - < Dockerfile
docker tag [sha] tgeorgel/trellis-cd:[TAG]
docker push tgeorgel/trellis-cd:[TAG]