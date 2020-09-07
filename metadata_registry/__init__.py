import markdown
from flask import Flask, request
from flask_restful import Resource, Api, reqparse
from flask_jwt import JWT, jwt_required
from sqlalchemy import create_engine
from json import dumps
import pprint
from flask_jsonpify import jsonify
import psycopg2
from config import config
import base64
import os
import markdown
import subprocess
import re

params = config()

app = Flask(__name__)
api = Api(app)



"""
**Definition**
Display the API documentation at the browser
"""
@app.route("/")
def index():
    """Present some documentation"""
    with open(os.path.dirname(app.root_path) + '/README.md', 'r') as markdown_file:
        content = markdown_file.read()
        return markdown.markdown(content)


class FetchMetadata(Resource):
     TABLE_NAME = 'bracken_results'

     parser = reqparse.RequestParser()
     parser.add_argument('run_accession',
                         type=str,
                         required=True,
                         help="This field is mandatory, it is the run_accession identifier eg: ERRXXXX, SRRXXXX, DRRXXXXX")
     parser.add_argument('top',
                         type=str,
                         required=False,
                         help="extract all bracken metadata for a given run accession sets")
     def get(self):
        data = FetchMetadata.parser.parse_args()
        accessions = {'run_accession': data['run_accession']}
        top = data['top']
        with psycopg2.connect(**params) as conn:
             with conn.cursor() as cursor:
                 query = """ 
                 select run_accession, name, taxonomy_id,kraken_assigned_reads, added_reads, new_est_reads, 
                    fraction_total_reads from 
                     (SELECT *,
                     rank() OVER (PARTITION BY run_accession ORDER BY fraction_total_reads DESC)
                     FROM bracken_results where run_accession= ANY(%s)) ranked_scores 
                     where rank <= (%s)
                 """
                 acc = accessions['run_accession'].split("|")
                 cursor.execute(query, (acc,top))
                 cols = list(map(lambda x: x[0], cursor.description))
                 if not cursor.rowcount:
                     return {'message': 'run accession not found', 'data': {}}, 404
                 result = {'data': [dict(zip(tuple(cols), i)) for i in cursor.fetchall()]}
                 result = jsonify(result)
                 return result




api.add_resource(FetchMetadata, '/fetchmetadata')



