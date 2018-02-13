import json
from pprint import pprint
import math
import oct2py
from wavelength_to_rgb import wavelength_to_rgb
from make_bayesdb_files import make_bayesdb_files
import os
from experimental_condition import ExperimentalCondition
from replicate_manager import ReplicateManager

class Analysis:
  def __init__(self,analysis_filename, cytometer_filename, exp_data_filename, cm_filename, octave):
    self.octave = octave
    with open(analysis_filename) as f:
      self.obj = json.load(f)['tasbe_analysis_parameters']
    with open(cytometer_filename) as f:
      self.cytometer_config = json.load(f)['tasbe_cytometer_configuration']
    self.exp_data_filename = exp_data_filename
    self.cm_filename = cm_filename
    self.analysis_filename = analysis_filename

    folder_path = os.sep.join(self.obj['output']['file'].split(os.sep)[:-1])
    if not os.path.exists(folder_path):
      os.makedirs(folder_path)

    if 'point_clouds' in self.obj.get('additional_outputs', []) or 'bayesdb_files' in self.obj.get('additional_outputs', []):
      self.octave.eval('TASBEConfig.set("flow.outputPointCloud", true);')
      folder = os.path.split(self.obj['output']['file'])[0]
      print('\n\n++++++++\n' + folder + '\n+++++++++\n\n')
      self.octave.eval('TASBEConfig.set("flow.pointCloudPath","{}");'.format(folder))
    else:
      self.octave.eval('TASBEConfig.set("flow.outputPointCloud", false);')

  def analyze(self):
    self.octave.eval('bins = BinSequence(0,0.1,10,\'log_bins\');');
    self.octave.eval('ap = AnalysisParameters(bins,{});')
    self.octave.eval('ap = setMinValidCount(ap,100\');')
    self.octave.eval('ap = AP=setPemDropThreshold(ap,5\');');
    self.octave.eval('ap = setUseAutoFluorescence(ap,false\');')
     
    self.octave.eval('[results sample_results] = per_color_constitutive_analysis(cm,file_pairs,channel_names,ap);')  
    a = self.octave.eval('length(sample_results)')
    
    self.results = []
    #self.octave.eval('results[1]')
    
    for i in xrange(1,int(a)+1):
      self.octave.eval('results {{{}}}.channel_names = channel_names;'.format(i))
      r = self.octave.eval('results{{{}}};'.format(i))
      r['condition'] = self.octave.eval('file_pairs{{{},1 }};'.format(i))
      self.results.append(r)
    
    longnames = self.octave.pull('channel_long_names')
    if type(longnames) == oct2py.io.Cell: longnames = longnames.tolist()
    if type(longnames[0]) == list: longnames = longnames[0]
    colorspecs = []
    for longname in longnames:
        colorspecs.append(wavelength_to_rgb([x['emission_filter']['center'] for x in self.cytometer_config['channels'] if x['name'] == longname][0]))
    colorspecs = '{' + ','.join(colorspecs) + '}'
    self.octave.eval('outputsettings = OutputSettings("Exp", "", "", "{}");'.format(self.obj.get('output', {}).get('plots_folder', 'plots')))
#     self.octave.eval('outputsettings.FixedInputAxis = [1e4 1e10];')
    self.octave.eval('plot_batch_histograms(results, sample_results, outputsettings, {}, cm);'.format(colorspecs))

    self.print_bin_counts(self.obj['channels'])
    if 'bayesdb_files' in self.obj.get('additional_outputs', []):
      make_bayesdb_files(self.exp_data_filename, self.analysis_filename, self.cm_filename)



  def print_bin_counts(self,channels):

    replicater = ReplicateManager()
    print 'printing bin channels'

    a = self.octave.eval('length(channel_names)')
    color_order = {}
    
    for i in xrange(1,int(a)+1):
      color_order[self.octave.eval('channel_names{{1,{}}}'.format(i))] = i-1

    with open(self.obj['output']['file'],'w') as output_file: 

      output_file.write('condition,channel,geo_mean,{}\n'.format(','.join([str(math.log(i,10)) for i in self.results[0].bincenters.tolist()[0]])))
      for c in channels:
        index = color_order[c]
        for r in self.results:
          csv_results = ','.join([str(i[index]) for i in r.bincounts.tolist()])
          print 'getting ',r['condition']

          e = ExperimentalCondition("https://hub-api.sd2e.org/sparql",r['condition'])

          e = e.conditions
          condition_object = {}
          for key in e:
            if key != 'plasmids':
              condition_object[key.replace('_measure','')] = 1 if float(e[key]) != 0.0 else 0
            else:
              condition_object['plasmid'] = '_'.join( map(lambda s: s.split("#")[1],e[key]))

          rep = replicater.get_replicate(str(e))
          condition_object['replicate'] = rep
          print rep
          print e

          output_file.write('{},{},{},{}\n'.format(condition_object,c,r['means'],csv_results))
