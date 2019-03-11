# epicsmng docker images

These images are developed to be used as base images for other projects.

## How to build images

These images have to be built with the main repository folder as context:

``docker build -t epicsmng:ubuntu -f docker/Dockerfile.ubuntu .``

or 

``docker build -t epicsmng:centos -f docker/Dockerfile.centos .``
