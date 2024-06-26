from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
import os
import datetime
import certifi
import tfvars
from openai import OpenAI

ca = certifi.where()
tfv = tfvars.LoadSecrets()
openaiclient = OpenAI( api_key=tfv["openai_key"])

response = openaiclient.embeddings.create(
    input="give me socks for kids",
    model="text-embedding-3-small"
)

#print(response.data[0].embedding)
mongodb_uri=os.popen(f"terraform output atlas_cluster_connection_string").read().replace('"', '').strip()
uri = "mongodb+srv://"+tfv["mongodbatlas_user"]+":"+tfv["mongodbatlas_password"]+"@"+ mongodb_uri


# Create a new client and connect to the server
client = MongoClient(uri, server_api=ServerApi('1'),tlsCAFile=ca)
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
       'queryVector'  : response.data[0].embedding, 
       'numCandidates': 200, 
       'limit': 10
    }
  }, {
    '$project': {
      '_id': 0, 
      'articleType': 1,
      'size': 1,
      'fashionType': 1,
      'brandName': 1,
      'baseColor': 1,
      'gender': 1,
      'season': 1,
    
      'score':
        {
        '$meta': 'vectorSearchScore'
      }
    }
  }
]

# run pipeline
result = client[tfv["mongodbatlas_project_name"]+"-"+tfv["mongodbatlas_environment"]][tfv["mongodbatlas_collection"]].aggregate(pipeline)
print(result)
# print results
for i in result:
    print(i)
