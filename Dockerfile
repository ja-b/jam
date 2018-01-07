FROM centos:7

# Install python deps
RUN yum install -y python python-devel python-setuptools git mysql-devel gcc && easy_install pip

WORKDIR /app/
ADD requirements.txt ./

# Install pip application deps
RUN pip install -r requirements.txt

ADD . .
WORKDIR /app/jam/

CMD python app.py
