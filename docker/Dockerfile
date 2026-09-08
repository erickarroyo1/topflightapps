# Pinned by digest, not just by tag: a tag can be repointed at a different image.
# Resolved from docker.io/library/python:3.12-slim on 2026-09-08.
FROM python:3.12-slim@sha256:78387bc3881b8273120a12ebe6c1ab22b018ccc2c9adf565ae1ac9b536e184ea
RUN apt-get update && apt-get install -y --no-install-recommends python3-mysqldb && rm -rf /var/lib/apt/lists/*
ENV PYTHONUNBUFFERED True
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
RUN pip install --no-cache-dir -r requirements.txt
RUN useradd -r -u 10001 app && chown -R app:app $APP_HOME
USER app
CMD ["python3", "app.py"]
