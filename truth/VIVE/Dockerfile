# Use the official Python image from the Docker Hub with the specific version 3.10.9
FROM python:3.10.9-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Install Python packages listed in requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project files into the container
COPY . .

# Set the default command to execute when running the container
CMD ["bash"]
