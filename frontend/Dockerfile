# Use the official Node.js image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the application code
COPY . .

# Expose the development port
EXPOSE 3000

# Start the Vite development server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]