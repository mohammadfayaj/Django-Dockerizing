# Welcome to django-docarizations
<code>Django - Docker - gunicorn - nginx</code>

> Docker’s main benefit is to package applications in “containers,” so they’re portable for any system running the Linux operating system (OS) or Windows OS. With Docker, you can isolate applications from their underlying infrastructure so that software delivery is faster than ever.
> > Container is a Docker image instance & You can run 1000+ containers from the same Image.

> Gunicorn (Green Unicorn) is a pure-Python HTTP server for WSGI applications. For WSGI applications that can run multiple Python concurrent processes within a single dyno. it is a stable, commonly-used part of web app deployments that's powered some of the largest Python web applications in the world, such as Instagram.
>> TCP (Transmission Control Protocol) socket is one endpoint of a two-way communication link between two programs running on the network.

> Nginx uses an asynchronous, event-driven approach where requests are handled in a single thread. nginx is an HTTP and reverse proxy server to serve static content 


This is a simple django app & I'm going to explain. How am i dockerized this app.

So, Frist of all look through the file statcture. This is importance because if statcture dose not match, Docker will give you an error.

![Optional Text](https://github.com/mohammadfayaj/Django-Dockerizing/blob/a7947f320b31ac1706a3a757bca5b509924634ef/tree.png)


#### 1. Create a file called <code>Dockerfile</code> Without any extention
```
#Alpine is a Linux distribution built around musl,libc and BusyBox.
FROM python:3.8.8-alpine

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# To set working directory in the image
WORKDIR /project/

RUN pip install --upgrade pip 
# copy requirements.txt from root directory and then send it to the image working directory
COPY ./requirements.txt /project/requirements.txt
RUN pip install -r requirements.txt

# Copy whole root project by "." and, Send it in the image working directory
COPY . /project/

# copy project/scripts and, set it to the image - project/scripts directory
COPY ./scripts /project/scripts/

# command to run entrypoint.sh
COPY ./scripts/entrypoint.sh /project/scripts/
ENTRYPOINT ["sh", "/project/scripts/entrypoint.sh"]

```

#### 2. Create a new file <code>docker-compose.yml</code>

```
version: '3.9'

services:
# this is a gunicorn server, you can name what ever you want, I call it 'django_gunicorn'
  django_gunicorn:
    build:
      context: .
    volumes:
      - static:/static/
    env_file:
      - ./project/.env
    ports:
      - "8000:8000"

# This is nginx server, and again you can rename it
  django_nginx:
    build: ./nginx
    volumes:
      - static:/static/
    ports:
      - "80:8080"
    # nginx server depends_on gunicorn server so docker-compose can build it together
    depends_on:
      - django_gunicorn

""" I'm not using any database system but if you want it probable this way """

  # mysql:
  #   build: ./mysql
  #   container_name: mysql
  #   ports:
  #     - 3306:3306
  #   volumes:
  #     - data-volume:/mysql/
  #   environment:
  #     - MYSQL_ROOT_PASSWORD=password
  #     - MYSQL_DATABASE=django
  #   healthcheck:
  #     test: "exit 0"

volumes:
  static:

```
> >Docker volumes persist data in Docker containers. When a Docker container is destroyed, it's entire file system is destroyed too. So if we want to keep this data, it is necessary that we use Docker volumes

#### 3. Create Scripts Directory inside the root directory
> inside scripts directory create a file called <code>entrypoint.sh</code>

```
#!/bin/sh

# This is for error handling if something's bad it will stop executing next.
set -e 

cd ./project/
python manage.py collectstatic --no-input
python manage.py migrate

'''
instance of calling django run-server, we call gunicorn server to connect our django wsgi server, 
This is the whole purpose 
of gunicorn and docker container to run our django application
'''
gunicorn project.wsgi:application --bind 0.0.0.0:8000


```


### 4. Create a Directory called <code>nginx</code> inside nginx we have two files 
0. Dockerfile
1. default.conf 

Dockerfile will create nginx image 
```
FROM nginx:1.19.0-alpine

COPY ./default.conf /etc/nginx/conf.d/default.conf

```

After creating nginx image now create a file <code>default.conf</code>
```
'''
this will call gunicorn_server at port 8000
here, 
django_gunicorn is a gunicorn server, we define it in the docker-compose.yml file
'''
upstream gunicorn_server {
	server django_gunicorn:8000;
}

server {
    ''' nginx will listen port 8000, and serve static content with is port '''
	listen 0.0.0.0:8080;

	# server_name example.com
	# if ($http_x_forwarded_proto = "http") {
	# 	return 301 https://$server_name$request_url;
	# }

	location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		if (!-f $request_filename) {
			proxy_pass http://gunicorn_server;

		}
	}

	location /static/ {
		alias /static/;
	}
	
	location /media/  {
        alias /media/;
    }


}

```
> If you don't define this piece of code django will give an error like <code>Disallowedhost at / Invaild HTTP_HOST header </code>
```
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;

```

Now time to build our application, inside the root directory type
<code>docker-compose up --build</code>


now you are good to go.

Open up a browser and type <code>127.0.0.1</code>
and check the logs. To see if static file server or not, Go to
<code>127.0.0.1/admin</code>

##### If any things i miss, Feel free to commit or create an issue
