# Use the official Python image from the Docker Hub with the specific version 3.12.5
FROM python:3.12.5-slim

# Install git, Boost, and other dependencies required for building GTSAM
RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        git \
        build-essential \
        cmake \
        libboost-all-dev

# Clone the GTSAM repository
RUN git clone https://github.com/borglab/gtsam.git /usr/src/gtsam

# Set the working directory to GTSAM directory
WORKDIR /usr/src/gtsam

RUN python -m pip install pyparsing>=2.4.2 numpy>=1.11.0

# Build and install GTSAM with Python bindings to a custom directory
RUN mkdir build \
    && cd build \
    && cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/src/gtsam/build \
        -DGTSAM_BUILD_PYTHON=1 \
        -DGTSAM_PYTHON_VERSION=3.12.5 \
        .. \
    && make -j$(nproc) install \
    && make python-install

# Set the working directory in the container
WORKDIR /usr/src/app

# Install Python packages listed in requirements.txt
RUN --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt

# Update the PYTHONPATH environment variable to include the GTSAM Python bindings
ENV PYTHONPATH=/usr/src/gtsam/build/python:$PYTHONPATH

# Copy the rest of the project files into the container
COPY . .

# Set the default command to execute when running the container
CMD ["bash"]
