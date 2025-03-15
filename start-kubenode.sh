#!/bin/bash

uuid=$(uuidgen)
containerProductUuidFileName="/var/tmp/container-product-uuid-$uuid"
echo "$uuid" > $containerProductUuidFileName

docker run \
-itd \
--rm \
--privileged \
--volume $containerProductUuidFileName:/sys/class/dmi/id/product_uuid:ro \
amaic/kubenode:latest