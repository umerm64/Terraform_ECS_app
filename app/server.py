#!/usr/bin/python3
import random
import time
from flask import Flask, send_file
import os

app = Flask(__name__)

@app.route('/')
def home():
    res = """Test server at ECS\n\r
Following routes are available right now\n\r
/time : get current timestamp\n\r
/random : 10 random numbers from 0 - 5\n\r
"""
    return res, 200

@app.route('/time')
def getTimestamp():
    # timestamp in seconds
    ts = int(time.time())
    print(ts)
    return str(ts), 200

@app.route("/random")
def getRandomNums():
    res = ""
    for i in range(10):
        rand = random.randint(0, 5)
        res += str(rand) + ","
    res = res[:-1]
    return res, 200

port = int(os.environ.get('PORT', 5000))
app.run(debug=False, host='0.0.0.0', port=port)
