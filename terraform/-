from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
import os
import datetime
from openai import OpenAI
client = OpenAI()

password=os.environ['MONGODB_USER']
password=os.environ['MONGODB_KEY']
response = client.embeddings.create(
    input="Your text string goes here",
    model="text-embedding-3-small"
)

print(response.data[0].embedding)

uri = "mongodb+srv://os.environ['MONGODB_USER']:os.environ['MONGODB_KEY']@myfirstproject-dev-clus.9rczhdt.mongodb.net/?retryWrites=true&w=majority&appName=myFirstProject-dev-cluster"
# Create a new client and connect to the server
client = MongoClient(uri, server_api=ServerApi('1'))
# Send a ping to confirm a successful connection
try:
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)




# define pipeline
pipeline = [
  {
    '$vectorSearch': {
      'index': 'vector-search', 
       'path': 'vector', 
       'queryVector'  : response.data[0].embedding 
       'numCandidates': 200, 
       'limit': 10
    }
  }, {
    '$project': {
      '_id': 0, 
      'articleType': 1, 
        {
        '$meta': 'vectorSearchScore'
      }
    }
  }
]

# run pipeline
result = client["sample_mflix"]["embedded_movies"].aggregate(pipeline)

# print results
for i in result:
    print(i)
