import pandas as pd

# why not hire mturk workers to rate posts as adhering to categories in CMNI or something. then train model to classify the rest. Do it this way?
# another better way?

# also for validation pick 30 pairs of posts randomly
# say which one is higher yourself
# then rank how many you got right

df = pd.read_csv("df_yolow_clean_1.csv")
df = df.drop_duplicates(subset="text_fpath")

import string
import numpy as np
from nltk.tokenize import word_tokenize
from gensim.models import Word2Vec
from scipy.spatial.distance import cosine
import nltk
nltk.download('punkt_tab')

if(True):
    import re
    from nltk.tokenize import word_tokenize
    from nltk.corpus import stopwords
    from nltk.stem import WordNetLemmatizer

    nltk.download('stopwords')
    nltk.download('wordnet')

    stop_words = set(stopwords.words('english'))
    lemmatizer = WordNetLemmatizer()

    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"  # Emoticons
        "\U0001F300-\U0001F5FF"  # Symbols & pictographs
        "\U0001F680-\U0001F6FF"  # Transport & map symbols
        "\U0001F700-\U0001F77F"  # Alchemical symbols
        "\U0001F780-\U0001F7FF"  # Geometric shapes
        "\U0001F800-\U0001F8FF"  # Supplemental arrows
        "\U0001F900-\U0001F9FF"  # Supplemental symbols & pictographs
        "\U0001FA00-\U0001FA6F"  # Chess symbols, etc.
        "\U0001FA70-\U0001FAFF"  # More symbols
        "\U00002702-\U000027B0"  # Dingbats
        "\U000024C2-\U0001F251"  # Enclosed characters
        "]+", flags=re.UNICODE
    )

    def preprocess(text):
        if not isinstance(text, str):  # Handle NaN or non-string entries
            return []

        text = text.lower()
        text = re.sub(r'http\S+|www\S+', '', text)
        text = re.sub(r'\d+', '', text)
        text = emoji_pattern.sub(r'', text)
        text = text.translate(str.maketrans("", "", string.punctuation))
        tokens = word_tokenize(text)
        tokens = [lemmatizer.lemmatize(word) for word in tokens if word not in stop_words]

        return tokens

    df['processed_text'] = df['text_content'].apply(preprocess)
    tokenized_captions = df['processed_text'].tolist()
    model = Word2Vec(sentences=tokenized_captions, vector_size=100, window=5, min_count=1, workers=4)
    model.save("word2vec_politicians.model")
    print("Word2Vec training completed and model saved!")

# next on the todo is to really think about the words you want here:
violence_words = ["violence", "aggression", "attack", "fight", "war", "brutal", "destroy", "enemy", "threat", "force"]
anger_words = ["anger", "rage", "furious", "hostile", "resentment", "outrage", "wrath", "fury", "vengeance"] # these are bad words

# as per wedgewood, connell, wood:

aggressiveness_words = ['fight', 'defend', 'attack', 'dominate', 'crush', 'destroy', 'enemy','force', 'warrior', 'war', 'fury', 'furious', 'vengeance'] # 'warrior', 'war', 'relentless','outrage', 'stormed', 'violent', 'assualt', 'shooting', 'murder', 'unapologetic', 'kill']
#aggressiveness_words = ['fighting', 'defend', 'attack', 'dominate', 'crush', 'destroy', 'enemy', 'force', 'warrior', 'outrage', 'stormed','fought'] # 'relentless', 'outrage', 'stormed', 'violent', 'shooting']
competitiveness_words = ['win', 'rival', 'beat', 'opponent', 'compete', 'victory', 'champion', 'proud', 'practice', 'relentless'] #'beat', 'relentless', 'champion', 'proud', 'practice', 'sport', 'range']
strength_words = ['strong', 'strength', 'powerful', 'force', 'might', 'solid', 'protect', 'hero', 'secure', 'safe','control'] # 'solid', 'protect', 'hero', 'secure', 'safe', 'protect', 'serve', 'defense', 'practice', 'control']
toughness_words = ['violence', 'fearless', 'tough', 'toughness', 'untouchable', 'hardened', 'brave', 'resilience', 'danger']  #'impervious', 'invincible', 'relentless', 'brave', 'danger']
emotion_words = ['rational', 'sacrifice', 'logical', 'realistic', 'selflessness', 'responsible'] #['unemotional', 'restrained', 'composed', 'cold', 'distant', 'calculated', 'rational', 'logical', 'sacrifice','duty', 'accountable'] # needs work
heterosexuality_words = ['wife', 'husband', 'straight', 'wedding', 'commitment', 'family'] # needs work
conservatism_words = ['conservative','liberal','democrat','republican','trump','biden']
_2a_words = ['gun','second','2nd','amendment','nra']

def sentence_similarity(sentence, reference_words):
    words = [word for word in sentence if word in model.wv]  # Keep only words in vocab
    if not words:
        return 0  # If no valid words, similarity is 0
    sentence_vector = np.mean([model.wv[word] for word in words], axis=0)  # Average vector
    
    ref_vectors = [model.wv[word] for word in reference_words if word in model.wv]  # Get vectors for ref words
    if not ref_vectors:
        return 0  # If no valid reference words, similarity is 0
    ref_vector = np.mean(ref_vectors, axis=0)  # Average reference vector
    
    return 1 - cosine(sentence_vector, ref_vector)  # Cosine similarity (1 = identical, 0 = unrelated)

df['similarity_to_aggressiveness'] = df['processed_text'].apply(lambda x: sentence_similarity(x, aggressiveness_words))
df['similarity_to_competitiveness'] = df['processed_text'].apply(lambda x: sentence_similarity(x, competitiveness_words))
df['similarity_to_strength'] = df['processed_text'].apply(lambda x: sentence_similarity(x, strength_words))
df['similarity_to_toughness'] = df['processed_text'].apply(lambda x: sentence_similarity(x, toughness_words))
df['similarity_to_emotion'] = df['processed_text'].apply(lambda x: sentence_similarity(x, emotion_words))
df['similarity_to_heterosexuality'] = df['processed_text'].apply(lambda x: sentence_similarity(x, heterosexuality_words))
df['similarity_to_conservatism'] = df['processed_text'].apply(lambda x: sentence_similarity(x, conservatism_words))
df['similarity_to_2a'] = df['processed_text'].apply(lambda x: sentence_similarity(x, _2a_words))

df.to_pickle("word2vec_with_similarity.pkl")
df.to_csv("word2vec_with_similarity.csv")

print("Similarity scores added and DataFrame saved!")

top_n = 5

def get_nearest_neighbors(word_list, model, top_n=top_n):
    neighbors = {}
    for word in word_list:
        if word in model.wv:
            neighbors[word] = [w for w, _ in model.wv.most_similar(word, topn=top_n)]
        else:
            neighbors[word] = ["N/A"]  # If word not in vocab, return N/A
    return neighbors

word_list = aggressiveness_words + competitiveness_words + strength_words + toughness_words + emotion_words + heterosexuality_words
nn = get_nearest_neighbors(word_list, model, top_n=top_n)

def generate_latex_table(nn):
    words = list(nn.keys())
    num_words = len(words)
    columns_per_table = 6
    top_n = len(next(iter(nn.values())))

    latex_code = ""

    for i in range(0, num_words, columns_per_table):
        sub_words = words[i:i + columns_per_table]

        latex_code += f"\\begin{{table}}[h]\n"
        latex_code += f"\\centering\n"
        latex_code += f"\\caption{{Caption {i // columns_per_table + 1}}}\n"
        latex_code += f"\\begin{{tabular}}{{{'|l' * len(sub_words)}|}}\n"
        latex_code += f"\\hline\n"

        latex_code += " & ".join(sub_words) + " \\\\\n"
        latex_code += "\\hline\n"

        for row in range(top_n):
            row_values = [nn[word][row] if row < len(nn[word]) else "N/A" for word in sub_words]
            latex_code += " & ".join(row_values) + " \\\\\n"

        latex_code += "\\hline\n"
        latex_code += "\\end{tabular}\n"
        latex_code += "\\end{table}\n\n"

    return latex_code

