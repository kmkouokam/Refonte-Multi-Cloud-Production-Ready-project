import os
from dotenv import load_dotenv
from functools import wraps
from pathlib import Path
import boto3 

load_dotenv()  # loads from .env file

def getenv_case_insensitive(var):
    """Get env var regardless of case"""
    return os.getenv(var) or os.getenv(var.lower()) or os.getenv(var.upper())

# Determine provider
provider = getenv_case_insensitive("DB_PROVIDER") or "AWS"
provider = os.getenv("DB_PROVIDER", "AWS").upper()

 
# Load DB credentials based on provider
if provider == "GCP":
    db_host = getenv_case_insensitive("gcp_db_host")
    db_name = getenv_case_insensitive("gcp_db_name")
    db_user = getenv_case_insensitive("gcp_db_username")
    db_pass = getenv_case_insensitive("gcp_db_password")
else:
    db_host = getenv_case_insensitive("aws_db_host")
    db_name = getenv_case_insensitive("aws_db_name")
    db_user = getenv_case_insensitive("aws_db_username")
    db_pass = getenv_case_insensitive("aws_db_password")

print(f"Connecting to {provider} database {db_name} at {db_host} as {db_user}")

 


from flask import (
    Flask,
    render_template,
    request,
    session,
    flash,
    redirect,
    url_for,
    abort,
    jsonify,
)
from flask_sqlalchemy import SQLAlchemy


basedir = Path(__file__).resolve().parent

# Build DATABASE_URL if not provided
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL and all([db_host, db_name, db_user, db_pass]):
    DATABASE_URL = f"postgresql://{db_user}:{db_pass}@{db_host}/{db_name}"
    os.environ["DATABASE_URL"] = DATABASE_URL

# Try to load DATABASE_URL from AWS SSM if still not set

if not DATABASE_URL:
    try:
        print("🔍 Attempting to load DATABASE_URL from AWS SSM...")
        ssm = boto3.client("ssm", region_name=os.getenv("AWS_REGION", "us-east-1"))
        param = ssm.get_parameter(Name="/flask-app/DATABASE_URL", WithDecryption=True)
        DATABASE_URL = param["Parameter"]["Value"]
        os.environ["DATABASE_URL"] = DATABASE_URL
        print("✅ Loaded DATABASE_URL from AWS SSM")
    except Exception as e:
        print(f"⚠️ Could not load DATABASE_URL from SSM: {e}")
        DATABASE_URL = None   

# optional fallback for local development
basedir = Path(__file__).resolve().parent
if not DATABASE_URL:
      DATABASE_URL = f"sqlite:///{Path(basedir).joinpath('flaskr.db')}" 
     
# Normalize URI prefix
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Flask configuration
USERNAME = os.getenv("FLASK_USERNAME", "admin")
PASSWORD = os.getenv("FLASK_PASSWORD", "admin")
SECRET_KEY = os.getenv("SECRET_KEY", "change_me")    

SQLALCHEMY_DATABASE_URI = DATABASE_URL
SQLALCHEMY_TRACK_MODIFICATIONS = False





# DATABASE = "flaskr.db"
# USERNAME = "admin"
# PASSWORD = "admin"
# SECRET_KEY = "change_me"
# url = os.getenv("DATABASE_URL", f"sqlite:///{Path(basedir).joinpath(DATABASE)}")

# if url.startswith("postgres://"):
#     url = url.replace("postgres://", "postgresql://", 1)

# SQLALCHEMY_DATABASE_URI = url
# SQLALCHEMY_TRACK_MODIFICATIONS = False


# create and initialize a new Flask app
app = Flask(__name__)
# load the config
app.config.from_object(__name__)
# init sqlalchemy
db = SQLAlchemy(app)

from project import models


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get("logged_in"):
            flash("Please log in.")
            return jsonify({"status": 0, "message": "Please log in."}), 401
        return f(*args, **kwargs)

    return decorated_function


@app.route("/")
def index():
    """Searches the database for entries, then displays them."""
    entries = db.session.query(models.Post)
    return render_template("index.html", entries=entries)


@app.route("/add", methods=["POST"])
def add_entry():
    """Adds new post to the database."""
    if not session.get("logged_in"):
        abort(401)
    new_entry = models.Post(request.form["title"], request.form["text"])
    db.session.add(new_entry)
    db.session.commit()
    flash("New entry was successfully posted")
    return redirect(url_for("index"))


@app.route("/login", methods=["GET", "POST"])
def login():
    """User login/authentication/session management."""
    error = None
    if request.method == "POST":
        if request.form["username"] != app.config["USERNAME"]:
            error = "Invalid username"
        elif request.form["password"] != app.config["PASSWORD"]:
            error = "Invalid password"
        else:
            session["logged_in"] = True
            flash("You were logged in")
            return redirect(url_for("index"))
    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    """User logout/authentication/session management."""
    session.pop("logged_in", None)
    flash("You were logged out")
    return redirect(url_for("index"))


@app.route("/delete/<int:post_id>", methods=["GET"])
@login_required
def delete_entry(post_id):
    """Deletes post from database."""
    result = {"status": 0, "message": "Error"}
    try:
        new_id = post_id
        db.session.query(models.Post).filter_by(id=new_id).delete()
        db.session.commit()
        result = {"status": 1, "message": "Post Deleted"}
        flash("The entry was deleted.")
    except Exception as e:
        result = {"status": 0, "message": repr(e)}
    return jsonify(result)


@app.route("/search/", methods=["GET"])
def search():
    query = request.args.get("query")
    entries = db.session.query(models.Post)
    if query:
        return render_template("search.html", entries=entries, query=query)
    return render_template("search.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 8080)))
