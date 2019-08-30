FROM python:3.6

WORKDIR /home/flask-docker-nginx

COPY requirements.txt wsgi.py uwsgi.ini ./

RUN python -m venv venv
RUN venv/bin/pip install --upgrade pip
RUN venv/bin/pip install -r requirements.txt

COPY app app

EXPOSE 5000

CMD ["venv/bin/uwsgi", "--ini", "uwsgi.ini"]
