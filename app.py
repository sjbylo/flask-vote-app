import os
import random
import json
import socket
import flask
import time

from datetime import datetime
from flask import Flask, request, make_response, render_template
from flask_sqlalchemy import SQLAlchemy

cache = {}
cache['fail'] = 0;

app = Flask(__name__)
basedir = os.path.abspath(os.path.dirname(__file__))
#dbhost  = os.environ.get('DB_HOST', '')
#dbport  = os.environ.get('DB_PORT', '')
#dbname  = os.environ.get('DB_NAME', '')
#dbuser  = os.environ.get('DB_USER', '')
#dbpass  = os.environ.get('DB_PASS', '')
#dbtype  = os.environ.get('DB_TYPE', '')

# These are the var names created via the RDS binding using the AWS Broker 
# DB_NAME: 
# ENDPOINT_ADDRESS: 
# MASTER_PASSWORD: 
# MASTER_USERNAME: 
# PORT:

# The default values ('db', 'vote' etc) are for making it easier to create this app in the OpenShift console after 
# setting up a DB call 'db'...

dbhost  = os.environ.get('ENDPOINT_ADDRESS', 'db')
dbport  = os.environ.get('PORT', '3306')
dbname  = os.environ.get('DB_NAME', 'vote')
dbuser  = os.environ.get('MASTER_USERNAME', 'user')
dbpass  = os.environ.get('MASTER_PASSWORD', 'password')
dbtype  = os.environ.get('DB_TYPE', '')

if dbtype == 'mysql':
   dburi  = dbtype + '://' + dbuser + ':' + dbpass + '@' + dbhost + ':' + dbport + '/' + dbname
elif dbtype == 'postgresql':
   dburi  = dbtype + '://' + dbuser + ':' + dbpass + '@' + dbhost + ':' + dbport + '/' + dbname
else:
   dburi = 'sqlite:///' + os.path.join(basedir, 'data/app.db')

app.config['SQLALCHEMY_DATABASE_URI'] = dburi
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ECHO'] = False

db = SQLAlchemy(app)

class Poll(db.Model):
  id       = db.Column(db.Integer, primary_key=True)
  name     = db.Column(db.String(30), unique=True)
  question = db.Column(db.String(90))
  stamp    = db.Column(db.DateTime)
  options  = db.relationship('Option', backref='option', lazy='dynamic')

  def __init__(self, name, question, stamp=None):
      self.name  = name
      self.question = question
      if stamp is None:
         stamp = datetime.utcnow()
      self.stamp = stamp

class Option(db.Model):
  id      = db.Column(db.Integer, primary_key=True)
  text    = db.Column(db.String(30))
  poll_id = db.Column(db.Integer, db.ForeignKey('poll.id'))
  poll    = db.relationship('Poll', backref=db.backref('poll', lazy='dynamic'))
  votes   = db.Column(db.Integer)

  def __init__(self, text, poll, votes):
      self.text = text
      self.poll = poll
      self.votes = votes

@app.route('/')

@app.route('/index.html')
def index():
    return render_template('index.html', hostname=hostname, poll=poll)

@app.route('/vote.html', methods=['POST','GET'])
def vote():
    has_voted = False
    vote_stamp = request.cookies.get('vote_stamp')

    if request.method == 'POST':
        has_voted = True
        vote = request.form['vote']
        if vote_stamp:
           print(("This client has already voted! The vote stamp is : " + vote_stamp))
        else:
           print ("This client has not voted yet!")
           voted_option = Option.query.filter_by(poll_id=poll.id,id=vote).first() 
           voted_option.votes += 1
           db.session.commit()
    
    # if request.method == 'GET':
    options = Option.query.filter_by(poll_id=poll.id).all()        
    resp = make_response(render_template('vote.html', hostname=hostname, poll=poll, options=options))
    
    if has_voted:
       vote_stamp = hex(random.getrandbits(64))[2:-1]
       print ("Set coookie for voted")
       resp.set_cookie('vote_stamp', vote_stamp)

    if cache['fail'] == 1:
        cause_some_failure(5)

    return resp

@app.route('/results.html')
def results():
    results = Option.query.filter_by(poll_id=poll.id).all()
    return render_template('results.html', hostname=hostname, poll=poll, results=results)

@app.route('/health')
def health():
    if cache['fail'] == 1:
        flask.abort('500')
    else:
        return 'ok'

@app.route('/fail')
def fail():
    cache['fail'] = 1;
    return 'Server failing ...'

if __name__ == '__main__':

    print(("Connect to : " + dburi))

    wait = 1
    while True:
        try:
            db.create_all()
        except Exception as e: 
            print(e)
            print ("Database connection failed ... sleep\n")
        time.sleep(wait)
        wait = 10

    db.session.commit()
    hostname = socket.gethostname()
         
    print ("Check if a poll already exists in the db")
    # TODO check the latest one filtered by timestamp
    poll = Poll.query.first()
    
    if poll:
       print ("Restart the poll")
       poll.stamp = datetime.utcnow()
       db.session.commit()
    
    else:
       print ("Load seed data from file")
       try: 
           with open(os.path.join(basedir, 'seeds/seed_data.json')) as file:
               seed_data = json.load(file)
               print ("Start a new poll")
               poll = Poll(seed_data['poll'], seed_data['question'])
               db.session.add(poll)
               for i in seed_data['options']:
                   option = Option(i, poll, 0)
                   db.session.add(option)
               db.session.commit()

       except:
          print ("Cannot load seed data from file")
          poll = Poll("", "")

    app.run(host='0.0.0.0', port=8080, debug=False)

