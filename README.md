Multiarch Docker Containers
--
[![Build Status](https://travis-ci.org/lwolf/docker-multiarch.svg?branch=master)](https://travis-ci.org/lwolf/docker-multiarch)

This repo contains daily builds of many different software I use in my K8s clusters.
Currently all images are compatible with the following architectures:

* amd64
* arm64
* arm7 

Images are built compliant with v2.2 of the Docker manifest API. No need to specify separate images for different architectures (particularly annoying if you have an architecturally heterogeneous cluster); the Docker client infers for you which image to pull.

Current content
--

| Name  | Image |
| ------------- | ------------- |
| flannel  | [lwolf/flannel](https://hub.docker.com/r/lwolf/flannel)  |
| kubernetes-dashboard  | [lwolf/kubernetes-dashboard](https://hub.docker.com/r/lwolf/kubernetes-dashboard)  |
| prometheus-node-exporter  | [lwolf/node-exporter](https://hub.docker.com/r/lwolf/node-exporter)  |
| tiller   | [lwolf/helm](https://hub.docker.com/r/lwolf/helm) |
