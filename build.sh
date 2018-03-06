COMMAND=$1

# Split the build process to build a core image, then base the
# app image off of it. This prevents the time-consuming process
# of installing >1000+ packages from being triggered by Docker
# cache invalidation.

BUILD_IMAGE="sd2e/fcs-etl:build"

docker build --pull -f Dockerfile.base -t ${BUILD_IMAGE} . && \
docker build -f Dockerfile -t fcs-etl .

if [ "$COMMAND" == "push" ]
then
    echo "Pushing build support image ${BUILD_IMAGE} to registry"
    docker push ${BUILD_IMAGE}
fi
