import json
import experimental_condition as ec
import re
import csv
import os

def matlab_sanitize(instr): #TASBE replaces hyphens and whitespace in certain strings with underscores
  return re.sub('[-\s]', '_', instr)

def make_bayesdb_files(exp_data, analysis_params, cm_params):
  ec_cache = {}
  expfiles = json.load(open(exp_data, 'rb'))['tasbe_experimental_data']['samples']

  input_cols = []
  output_cols = []

  aparams = json.load(open(analysis_params, 'rb'))
  channels = aparams['tasbe_analysis_parameters']['channels']
  output_dir = aparams['tasbe_analysis_parameters']['output'].get('output_folder', 'output')
  label_map = json.load(open(cm_params, 'rb'))['tasbe_color_model_parameters']['channel_parameters']
  label_map = {matlab_sanitize(x['name']): x['label'] for x in label_map}

  print label_map

  for c in channels:
    if c not in output_cols:
      output_cols.append(c)

  big_csv = []

  for file_id,f in enumerate(expfiles):
    pointfile = os.path.join(output_dir, os.path.basename(re.sub('.fcs', '_PointCloud.csv', f['file'])))
    if f['sample'] not in ec_cache:
      ec_cache[f['sample']] = ec.ExperimentalCondition("https://hub-api.sd2e.org/sparql", f['sample']).conditions
    conditions = ec_cache[f['sample']]


    for c in conditions:
      if c not in input_cols:
        input_cols.append(c)

    if 'file_id' not in input_cols:
        input_cols.append('file_id')

    this_csv = csv.DictReader(open(pointfile, 'rb'))
    for row in this_csv:
      row = {label_map[x]: row[x] for x in row}
      row.update(conditions)
      row.update({'file_id':file_id})
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
  