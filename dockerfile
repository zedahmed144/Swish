# Use an official Node runtime as a parent image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Bundle app source inside Docker image
COPY . .

# Make port 80 available to the world outside this container
EXPOSE 80

# Define the command to run your app
CMD [ "npm", "start" ]
