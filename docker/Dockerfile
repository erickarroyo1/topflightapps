FROM python:3.9
RUN apt update && apt install -y python3-mysqldb
ENV PYTHONUNBUFFERED True
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python3", "app.py"]
