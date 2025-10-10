from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from db import DATABASE_URL

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
db = SQLAlchemy(app)

@app.route('/')
def hello():
    return "Flask app running!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
