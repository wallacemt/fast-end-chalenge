FROM nginx:latest
WORKDIR /app
COPY . /app
RUN cp -r /app/dist/* /usr/share/nginx/html/ && rm -rf /app
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]