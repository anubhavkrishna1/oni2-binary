# Clone the Oni2 repo
git clone https://github.com/onivim/oni2
cd oni2

# Patch Dockerfile to use almalinux:8 instead of centos:latest
grep -q '^FROM centos:latest' scripts/docker/centos/Dockerfile && \
sed -i 's|^FROM centos:latest|FROM almalinux:8|' scripts/docker/centos/Dockerfile || true

# Use our included script to setup a docker container
docker build --network=host -t centos scripts/docker/centos

# Now use that container to actually build an Oni2 AppImage.
# Bind the Oni2 folder to the volume so that it can access the source.
# We also bind ~/.esy such that the build steps are cached locally.
# This means subsequent builds are fast.
# You can clean that folder out to save space at the cost of build time for future
# builds.
docker container run --rm \
    --name centos \
    --network=host \
    --volume `pwd`:/oni2 \
    --volume ~/.esy:/esy/store \
    --cap-add SYS_ADMIN \
    --device /dev/fuse \
    --security-opt apparmor:unconfined \
    centos \
    /bin/bash -c 'cd oni2 && ./scripts/docker-build.sh'

# Wait 30-40 minutes on an average machine...
# This takes up to about an hour on CI though, so may be worth
# leaving for a bit!
# During the initial esy steps, there isn't much output, so you
# may end up waiting on `info fetching: done`. It will eventually
# finish the initial install and move on to building, which has output.

# Done!
# This should drop an AppImage binary off in _release in the Oni2
# folder.