FROM python:3.6.3-alpine3.6
COPY . .
RUN pip3 install -r requirements.txt
CMD ["mkdocs", "serve", "-q", "--strict", "--no-livereload", "-a", "0.0.0.0:8000"]
