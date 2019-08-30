# flask-docker-nginx

Let's you run a Flask app factory behind an Nginx server using Docker.

# Table of Contents

- [About](#about)
- [Usage](#usage)
- [Details](#details)

## About <a name="about"></a>

It was difficult to find a complete Flask tutorial with a _minimal working
example_ of running an app using Nginx. If you have Docker
and Docker Compose installed on your machine, cloning this repository and
following the (brief) [Usage](#usage) section will provide a working example.

We use Docker to run an [Nginx](https://hub.docker.com/_/nginx) reverse proxy
server. You might want to run your app behind something like Nginx (or
Gunicorn) for production deployments since such servers are more secure and are
optimized for high-traffic volumes and a variety of workloads.

## Usage <a name="usage"></a>

For a first run:

```
$ docker-compose up --build
```

On subsequent runs, the `--build` flag can be omitted; providing it builds the
image dictated by `Dockerfile`.

## Details <a name="details"></a>

The app is generated by an "app factory" called `create_app` within
`app/__init__.py`. Importing the `app` module in `wsgi.py` in the top level of
this repository will load `__init__.py`. In particular, the import statement

```python
from app import app
```

imports the app object instantiated at the bottom of `__init__.py`:

```python
from flask import Flask

def create_app():
    app = Flask(__name__)

    @app.route('/')
    def hello():
        return 'Hello, World!'

    return app

app = create_app()
```

This Flask object is then _callable_ by whatever framework is used to run the
app, whether that's by using `flask run`, `uswgi`, `Waitress`, etc.

Our uWSGI configuration file, `uwsgi.ini` has a `module` key like

```
module = wsgi:app
```

which indicates what file it needs to run (`wsgi`, with the `.py` extension
ommitted) and the name of the object that's callable (`app`, the name of the
Flask object initialized when we import the `app` module).

`uwsgi.ini` also indicates that we want to be talking to Nginx over a Unix
socket located at `/tmp/uwsgi.sock`. We've [set its privileges to
666](https://www.youtube.com/watch?v=AGHmr1NyBTw&feature=youtu.be&t=139) with

```
chmod-sock = 666
```

to make sure that Nginx will for sure be able to read from the socket. We've
told Ngnix to be communicating with the Flask app in `nginx.conf`, this block
in particular:

```
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  localhost;
        root         /var/www/html;

        location / {
            include uwsgi_params;
            uwsgi_pass unix:///tmp/uwsgi.sock;
        }
    }
```

Finally, in the `docker-compose.yml` file we've ensured that both the Flask app
and the Nginx server are able to access the _same_ Unix socket
`/tmp/uwsgi.sock` by declaring a volume called `app-volume` and mounting it in
the same place for both services.
