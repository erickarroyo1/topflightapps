#Author:Erick Arroyo
#TopFlight app
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
from sqlalchemy import text

app = Flask(__name__)

# Define connection details
db_username = os.environ.get("DB_USERNAME")
db_password = os.environ.get("DB_PASSWORD")
db_host = os.environ.get("DB_HOST")
db_port = os.environ.get("DB_PORT")
db_name = os.environ.get("DB_NAME")

@app.route("/")
def hello_world():
    """Topflightapp route"""
    connection_string = f"mysql+mysqlconnector://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}"
    engine = create_engine(connection_string, echo=True)
    
    with engine.connect() as connection:
        existing_record = connection.execute(text("SELECT * FROM employees WHERE id = :id"), {"id": 8}).fetchone()
        if not existing_record:
            connection.execute(text("INSERT INTO employees VALUES(8, 'test', 57, 75200.00)"))
            connection.commit()
    
    greeting = f"This is a Topflight APP running on ECS Fargate.\n\nThese are values from current RDS DB using tcp connection: {existing_record}\n\nAuthor:Erick Arroyo" if existing_record else "No record found."
    
    return greeting

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
