FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y nodejs npm ruby ruby-dev libffi-dev build-essential python-setuptools

RUN gem install sass -v 3.4.25
RUN gem install compass
#RUN pip install Pygments
RUN npm install -g coffee-script@1.12.7 docco-husky@0.3.3

WORKDIR /app
