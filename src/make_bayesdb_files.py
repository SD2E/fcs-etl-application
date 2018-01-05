import json
import experimental_condition as ec
import re
import csv
import os

def matlab_sanitize(instr): #TASBE replaces hyphens and whitespace in certain strings with underscores
  return re.sub('[-\s]', '_', instr)

def make_bayesdb_files():
  ec_cache = {}
  expfiles = json.load(open('/data/experimental_data.json', 'rb'))['tasbe_experimental_data']['samples']

  input_cols = []
  output_cols = []

  aparams = json.load(open('/data/analysis_parameters.json', 'rb'))
  channels = aparams['tasbe_analysis_parameters']['channels']
  output_dir = aparams['tasbe_analysis_parameters']['output'].get('output_folder', '/data/output')
  label_map = json.load(open('/data/color_model_parameters.json', 'rb'))['tasbe_color_model_parameters']['channel_parameters']
  label_map = {matlab_sanitize(x['name']): x['label'] for x in label_map}

  for c in channels:
    if c not in output_cols:
      output_cols.append(c)

  big_csv = []

  for f in expfiles:
    pointfile = os.path.join(output_dir, os.path.basename(re.sub('.fcs', '_PointCloud.csv', f['file'])))
    if f['sample'] not in ec_cache:
      ec_cache[f['sample']] = ec.ExperimentalCondition("http://hub.sd2e.org:8890/sparql", f['sample']).conditions
    conditions = ec_cache[f['sample']]
  
    for c in conditions:
      if c not in input_cols:
        input_cols.append(c)
  
    this_csv = csv.DictReader(open(pointfile, 'rb'))
    for row in this_csv:
      row = {label_map[x]: row[x] for x in row}
      row.update(conditions)
      big_csv.append(row)
    
  with open(os.path.join(output_dir, 'bayesdb_data.csv'), 'wb') as bayesdb_datafile:
    writer = csv.DictWriter(bayesdb_datafile, fieldnames=input_cols + output_cols)
    writer.writeheader()
    for row in big_csv:
      writer.writerow(row)

  with open(os.path.join(output_dir, 'bayesdb_metadata.json'), 'wb') as bayesdb_metafile:
    metadata = {}
    metadata['outcome-variables'] = []
    metadata['experimental-variables'] = []
    for i in input_cols:
      metadata['experimental-variables'].append({'name': i})
    for o in output_cols:
      metadata['outcome-variables'].append({'name': o})
    json.dump(metadata, bayesdb_metafile)
  