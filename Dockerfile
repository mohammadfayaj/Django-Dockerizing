#Alpine is a Linux distribution built around musl,libc and BusyBox.
FROM python:3.8.8-alpine

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# To set working directory in the image
WORKDIR /project/

RUN pip install --upgrade pip 
# copy reuiremnts.txt from project root and than send it to the image working directory
COPY ./requirements.txt /project/requirements.txt
RUN pip install -r requirements.txt

# Copy whole root project by "." and, Send it in the image working directory
COPY . /project/

# copy project/scripts and, Send it image project/scripts
COPY ./scripts /project/scripts/

# command to run entrypoint.sh
COPY ./scripts/entrypoint.sh /project/scripts/
ENTRYPOINT ["sh", "/project/scripts/entrypoint.sh"]







