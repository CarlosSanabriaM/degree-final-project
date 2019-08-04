FROM ubuntu:latest

# To build the image execute:
#  $ docker build . -t web_backend:latest

# To create a container that directly runs the backend execute:
#  $ docker run --name web_backend -p <host-port>:8080 -e PORT=8080 -i -t web_backend:latest
# where <host-port> is the port where the backend will be mapped in the host.
# The '-e PORT=8080' option specifies the value of the $PORT environment variable used in the CMD.
# This is done this way for testing locally. Heroku will set the PORT variable value.

# To create a container and enter inside it execute:
#  $ docker run --name web_backend -p <host-port>:8080 -e PORT=8080 -i -t web_backend:latest /bin/bash
# <host-port> is the port where the backend will be mapped in the host.

# The environment variables set using ENV will persist when a container is run from the resulting image
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Export CONF_INI_FILE_PATH environment variable to point to the production-conf.ini file.
ENV CONF_INI_FILE_PATH=/web_backend/production-conf.ini

RUN apt-get update --fix-missing && \
    apt-get upgrade -y && \
    # Install python3.6 and pip3
    apt-get install -y --no-install-recommends python3.6 python3-pip && \
    # Install Java JDK 8
    apt-get install openjdk-8-jdk -y && \
    # Remove apt content
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add environment variable JAVA_HOME that points to the java9 jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

# Copy the files of the topics_and_summary folder specified in the .dockerignore file
# (the .dockerignore excludes all files, except some scpecific ones of the topics_and_summary folder)
COPY $PWD/topics_and_summary /topics_and_summary

# Copy the files of the web_backend folder specified in the .dockerignore file
# (the .dockerignore excludes all files, except some scpecific ones of the web_backend folder)
COPY $PWD/web_backend /web_backend

# Replace the mallet-2.0.8/bin/mallet file with the mallet-docker file
# This files has some configuration to avoid memory issues in the container
RUN mv /web_backend/mallet-docker /topics_and_summary/mallet-2.0.8/bin/mallet

# Install the python packages needed for generating the binary distributions
RUN pip3 install wheel setuptools

# Create the binary distribution of web_backend
RUN cd /web_backend && \
    python3 setup.py bdist_wheel && \
    # Install the wheel file with the backend. The required packages will also be installed.
    pip3 install dist/*.whl && \
    # Remove the wheel file because it has big size
    rm dist/*.whl

# Create the binary distribution of topics_and_summary
RUN cd /topics_and_summary && \
    python3 setup.py bdist_wheel && \
    # Install the wheel file with the topics_and_summary library. The required packages will also be installed.
    pip3 install dist/*.whl && \
    # Remove the wheel file because it has big size
    rm dist/*.whl

# Install nltk resources in /nltk_data folder.
# Without the '-d /nltk_data' option, the nltk_data folder will be created inside
# /root folder, and the non-root user created by Heroku won't have access to it.
RUN python3 -m nltk.downloader -d /usr/share/nltk_data stopwords wordnet punkt

# Install waitress WSGI server
RUN pip3 install waitress

# Expose the port 8080 of the container.
# Expose is NOT supported by Heroku and will be ignored there.
EXPOSE 8080
# The EXPOSE instruction does not actually publish the port.
# It functions as a type of documentation between the person who builds the image
# and the person who runs the container, about which ports are intended to be published.

# Run the image as a non-root user. Heroku uses a non-root user to run the image, but doesn't
# use the user created here. This is only done for testing if the build is done correctly locally.
# Create the user myuser and his home directory with permissions over it
RUN useradd -m myuser

# Create a sh file with the command needed to start the web_backend waitress server.
# This file can be executed manually if the server stops.
RUN echo "waitress-serve --port=8080 --host='0.0.0.0' --call web_backend.app:create_app" > start-server.sh && \
    chmod +x start-server.sh && \
    chown myuser start-server.sh && \
    # In Heroku, all files/directories in the file system are owned by a non-root user,
    # except /dev, /proc and /sys, that are owned by root.
    # To simulate the same, we will change the owner of the following directories to be myuser.
    chown -R myuser /usr/local/lib/python3.6/dist-packages /usr/share/nltk_data /web_backend /topics_and_summary

# Login as non-root user to execute the app
USER myuser

# The CMD command can be overwritten when using 'docker run ...'
# If no command is specified when running the container, the container will
# start the backend and it will be accesible via the <host-port> port of the host specified in docker run.

# Heroku sets the $PORT variable. For testing locally, use '-e PORT=8080' option of 'docker run' command to set $PORT value.
CMD  waitress-serve --port=$PORT --host='0.0.0.0' --call web_backend.app:create_app
# To specify a different command that will be executed when the container runs, execute:
# $ docker run --name web_backend -p <host-port>:8080 -e PORT=8080 -i -t web_backend:latest <command-to-be-executed>
# where <command-to-be-executed> is the command to be executed.
