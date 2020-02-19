import numpy as np
import pandas as pd
import gensim

from keras.preprocessing.sequence import pad_sequences

# Mapping for most models: X is the concatenation of all features, 
# y the concatenation of all targets. 
# The column renaming is done for demonstration purposes.
def default_DataFrame2numpy_mapping(parameters, merge_X=True, merge_y=True):

    sparse_tfidf = lambda x: gensim_sparse_DataFrame2numpy(
            x, length=parameters['dictionary']['vocabulary_size'])

    return {
        'X': {
            'columns': {
                'premise_sparse_tfidf': {
                    'function': sparse_tfidf,
                    'name': 'premise_tfidf'},
                'conclusion_sparse_tfidf': {
                    'function': sparse_tfidf,
                    'name': 'conclusion_tfidf'},
                'tfidf_cosine_similarity': {},
            },
            'parameters': {
                'merge': merge_X,
            },
        },
        'y': {
            'columns': {
                'pro': {},
            },
            'parameters': {
                'merge': merge_y,
            }
        }
    }


def sequences_DataFrame2numpy_mapping(parameters, merge_X=True, merge_y=True):

    padding_doc = lambda x: keras_padding_text(
            x, maxlen=50 ) #later we can read this param from config file (emb size)

    return {
            'X':{
                    'columns': {
                            'premise_lemma_id' : {
                                    'function': padding_doc,
                                    'name': 'premise_seq'
                                    } ,
                            'conclusion_lemma_id' : {
                                    'function': padding_doc,
                                    'name': 'conclusion_seq'
                                    } 
                            },
                    'parameters': {
                            'merge': False
                            },
                    
                    },
            'y' : {
                    'columns': {
                            'pro': {},
                            },
                    'parameters': {
                            'merge': merge_y,
                            }
                    }
            }

def default_DataFrame2numpy_transform(column):
    """
        Default function to use for DataFrame columns.

        If some non numpy/pandas function needs to be applied, use
        np.vectorize(function) or DataFrame.apply(function).
    """
    return column.values[:, None]

def gensim_sparse_DataFrame2numpy(column, length=1000):
    """
        Transforms sparse tfidf vectors from gensim.models.TfidfModel.
        (the [(word_index, tfidf)] ones)
    """
    vectorized_sparse2full = np.vectorize(
            lambda sparse: gensim.matutils.sparse2full(
                sparse, length=length),
            signature='()->(n)')

    return vectorized_sparse2full(column.values)

def keras_padding_text(column, maxlen=50):
    """
    Add 0s at the end of the vector representation of each document so
    premise and conclusion have the same length
    """
    #return np.vectorize( pad_sequences(column.values, maxlen=maxlen), 
    #        signature='()->(n)')
    return pad_sequences(column.values, maxlen=maxlen) 

