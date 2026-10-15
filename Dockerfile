FROM nginx
RUN rm /usr/share/nginx/html/index.html
RUN echo "<h1><center>Hello Vaheed Ahmed Shaik</center></h1>" > /usr/share/nginx/html/index.html
