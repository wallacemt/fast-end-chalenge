FROM nginx:latest
COPY . /tmp/app
RUN cp -r /tmp/app/dist/* /usr/share/nginx/html/ && rm -rf /tmp/app
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]