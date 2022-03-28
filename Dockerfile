FROM node:8.11.1-alpine as build
ENV PORT=8000
RUN mkdir /app
WORKDIR /app
COPY package.json /app
RUN npm install
COPY . /app
RUN rm -fr /app/devops /app/Dockerfile /app/buildspec.yml
CMD ["npm", "start"]
