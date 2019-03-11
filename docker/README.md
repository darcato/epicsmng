# epicsmng docker images

These images are developed to be used as base images for other projects.

## Usage

One could use this docker image to run CI pipelines where an epics IOC has to be built:

```
image: darcato/epicsmng

build:
  script: 
    - epicsmng makemodules your_modules.conf
    - epicsmng configureioc your_modules.conf #optional
    - make
```

## How to build images

These images have to be built with the main repository folder as context:

``docker build -t epicsmng:ubuntu -f docker/Dockerfile.ubuntu .``

or 

``docker build -t epicsmng:centos -f docker/Dockerfile.centos .``
