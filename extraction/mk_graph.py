"""
Build the graph from the collection of csv files produced by an extraction
"""

import os

def main(csvdir, hashmap=None):

    # Init
    edges = []
    arg_labels = {}
    arg_nums = {}
    leaf_num = 0

    
    def get_num(arg_id):
        """Numerical id (auto-increment)"""
        if arg_id is None:
            print("arg_id is None !")
        if not arg_id in arg_nums.keys():
            arg_nums[arg_id] = len(arg_nums)
        return arg_nums[arg_id]

    
    def get_label(arg_id):
        """Label of argument (defaults to an empty string)"""
        if not arg_id in arg_labels.keys():
            arg_labels[arg_id] = ''
        return arg_labels[arg_id]


    # Read each csv file        
    filenames = os.listdir(csvdir)
    for filename in [f for f in filenames if f.endswith('.csv')]:

        # arg_id of the page (slashes was changed into tildes)
        if hashmap is None:
            child_id = filename.replace('.csv', '').replace('~','/')
        else:
            child_id = id2url(filename.replace('.csv', ''), hashmap)

        with open(os.path.join(csvdir, filename), 'r') as f:
            for line in f:
                line = line[:-1].split(';')
                if len(line) > 3:
                    parent_id = line[0]
                    parent_label = ";".join(line[1:-1])
                    weight = line[-1]
                else:
                    parent_id, parent_label, weight = line

                # Leaves do not have ids (i.e. does not have urls)
                if parent_id == '':
                    parent_id = 'leaf_%d'%leaf_num
                    leaf_num += 1

                # Record label
                arg_labels[parent_id] = parent_label

                # Build the edge with the numerical ids
                e = (get_num(parent_id), get_num(child_id), float(weight))
                edges.append(e)

    # Neo4j csvs
    with open('%s_nodes.csv'%csvdir, 'w') as f:
        print('n', 'url', 'label', sep=',', file=f)
        for arg_id, arg_num in arg_nums.items():
            print(arg_num, '"'+arg_id+'"', '"'+get_label(arg_id).replace('"',"'")+'"', sep=',', file=f)
    with open('%s_edges.csv'%csvdir, 'w') as f:
        print('n1', 'n2', 'weight', sep=',', file=f)
        for u,v,w in edges:
            print(u, v, w, sep=',', file=f)



def id2url(file_id, hashmap):
    """Get back original url from the csv's filename"""
    with open(hashmap, 'r') as f:
        for line in f:
            line = line.split(';')
            if line[1] == file_id+'\n':
                return line[0]
    return "None"



if __name__ == "__main__":

    # Parse command-line arguments
    import argparse
    parser = argparse.ArgumentParser(description="Parse the CSV files produced by an extraction and build the 'nodes' and 'edges' CSVs")
    parser.add_argument('directory')
    parser.add_argument('--hashmap', default=None)
    args = parser.parse_args()

    # Let's-a-go !
    main(args.directory, hashmap=args.hashmap)
