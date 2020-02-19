import argparse
from pathlib import Path

import pickle as pkl

from mllib import cfg

from mllib.preprocessing.dataset_preparation import utils
from mllib.models import training, simple_models, cocarascu


def cocarascu_model(training_argument_path, 
        validation_argument_path, dictionary_cfg_path, options=None):

    model = cocarascu.CocarascuModel(options=options)
    model = training.fit_2inputs(model,
            [lambda: pkl.load(training_argument_path.open('rb'))], 
            [lambda: pkl.load(validation_argument_path.open('rb'))], 
            cfg.load_merge([dictionary_cfg_path]))
    return model


def randomForest_model(training_argument_path, 
        validation_argument_path, dictionary_cfg_path, options=None):

    model = simple_models.RandomForestClassifier(n_estimators=30)
    model = training.fit_simple(model,
            [lambda: pkl.load(training_argument_path.open('rb'))], 
            [lambda: pkl.load(validation_argument_path.open('rb'))], 
            cfg.load_merge([dictionary_cfg_path]))
    return model

def main(training_argument_path, validation_argument_path,
        dictionary_cfg_path,
        model_path):

    training_argument_path = Path(training_argument_path)
    validation_argument_path= Path(validation_argument_path)
    dictionary_cfg_path = Path(dictionary_cfg_path)
    model_path = Path(model_path)

    #Gets profile file configuration
    cfg_dict = cfg.load_merge([dictionary_cfg_path])
    profile_name = cfg_dict['model']['profile']
    profile_cfg_path = dictionary_cfg_path.with_name(profile_name+".yaml")
    
    model_options = cfg.load_merge([profile_cfg_path])['profile'] #options
    model_name = model_options['model']
    
    model_list = {
            "cocarascu" : lambda options: cocarascu_model(training_argument_path,
                    validation_argument_path,
                    dictionary_cfg_path,
                    options=options),
            "randomforest": lambda options: randomForest_model(training_argument_path,
                    validation_argument_path,
                    dictionary_cfg_path,
                    options=options)
            }

    model = model_list[model_name](model_options)

    pkl.dump(model, model_path.open('wb'))

if __name__ == '__main__':
    argparser = argparse.ArgumentParser(
            description='Creates pandas.DataFrame pickle file for preprocessed arguments'
        )
    argparser.add_argument(
            'training_argument_path',
            help='path to training argument file',
        )
    argparser.add_argument(
            'validation_argument_path',
            help='path to validation argument file',
        )
    argparser.add_argument(
            'dictionary_cfg_path',
            help='path to dictionary cfg file',
        )
    argparser.add_argument(
            'model_path',
            help='path to dump trained model pickle', # hdf5 for NNs ?
        )
    args = argparser.parse_args()

    main(args.training_argument_path, args.validation_argument_path,
            args.dictionary_cfg_path,
            args.model_path)

