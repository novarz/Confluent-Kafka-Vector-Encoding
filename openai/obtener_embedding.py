import openai
import numpy as np
import argparse

def get_embedding(text, model="text-embedding-ada-002"):
    response = openai.Embedding.create(input=text, model=model)
    embedding = response['data'][0]['embedding']
    return embedding

def main(api_key, query):
    # Configura la clave API de OpenAI
    openai.api_key = api_key

    # Obtener el embedding
    embedding = get_embedding(query)

    # Convertir a numpy array
    embedding_np = np.array(embedding)

    print(embedding_np)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Obtener un vector embedding para un texto utilizando OpenAI.")
    parser.add_argument("--api_key", type=str, required=True, help="Clave API de OpenAI.")
    parser.add_argument("--query", type=str, required=True, help="Texto del query para obtener el embedding.")
    
    args = parser.parse_args()
    
    main(args.api_key, args.query)

