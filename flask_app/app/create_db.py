from flask import Flask
from app.db import db, get_database_url

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = get_database_url()
db.init_app(app)

with app.app_context():
    db.create_all()
    print("Database tables created successfully")
