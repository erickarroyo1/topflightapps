FROM python:3.9
RUN apt-get update && apt-get install -y --no-install-recommends python3-mysqldb && rm -rf /var/lib/apt/lists/*
ENV PYTHONUNBUFFERED True
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
RUN pip install --no-cache-dir -r requirements.txt
RUN useradd -r -u 10001 app && chown -R app:app $APP_HOME
USER app
CMD ["python3", "app.py"]
