# docker-app-template

This repository is a template for creating docker containers to house gui applications using X11.  Expectation for use is for users to update docker/Dockerfile to install their application and then run `./docker/make_container.sh` to create the container image and then run `./docker/run.sh` to execute the new container image.  From within the container users can then launch their app and see the GUI come up.
