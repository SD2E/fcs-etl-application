
import json
import argparse
from oct2py import Oct2Py, io
import pprint
import os

import nbformat as nbf
import datetime
import time
import shutil
import numpy as np

from cytometer import Cytometer
from process import ProcessControl
from color_model import ColorModel
from experiment import Experiment
from analysis import Analysis
from quicklook import Quicklook

import logging

logging.basicConfig(level=logging.DEBUG)

parser = argparse.ArgumentParser()
parser.add_argument('--cytometer-configuration',required=True,help='Configuration specifying channel names, excitation wavelengths, and filters')
parser.add_argument('--process-control',required=True,help='Configuration specifying calibration, negative control, and cross file pairs')
parser.add_argument('--experimental-data',required = True, help='Configuration specifying experimental conditions for input file')
parser.add_argument('--color-model-parameters',required=True,help='Configuration specifying how TASBE will build color model')
parser.add_argument('--analysis-parameters',required=True,help='Analysis file')

parser.add_argument('--junit-directory', help='Directory for junit xml to be written', default='/tmp/')

def main(args):
  '''
  Runs the whole sequence of FCS processing/analysis, using TASBE (a Matlab program) in
  an Oct2Py instance. The arguments above indicate the five configuration .json files 
  needed, plus the output directory for the XML file which will indicate warnings and
  errors during processing.
  
  In many places, we still have hard-coded default values in the manifest_to_fcs_etl_params
  reactor (which largey generates and assembles the .json files needed here). One major
  assumption that will likely need to change as things evolve is that there is only one
  channel of data.

  Inputs:

    analysis-parameters:      A .json file (e.g. analysis_parameters.json) specifying some
                              information about the analyses to be performed, the parameters
                              of these analyses, input/output locations of files, etc. If
                              reanalysis of the same data set is being performed, this is
                              generally the file that will be changed (most likely by TA1).
                              Currently, this gets built automatically by the
                              manifest_to_fcs_etl_params reactor, based on some assumptions
                              about default values.
                          
    cytometer-configuration:  A .json file (e.g. cytometer_configuration.json) describing
                              the state of the cytometer used to collect the data. This 
                              file will generally be provided by the TA3 performer, and 
                              will tend to change infrequently (if at all).

    experimental-data:        A .json file (e.g. experimental_data.json) describing the URI
                              and file locations for the raw data files to be included.
                              This file gets generated automatically by the 
                              manifest_to_fcs_etl_params reactor, based on the manifest.
                          
    color-model-parameters:   A .json file (e.g. color_model_parameters.json) describing the
                              species being analyzed, channels, bead peak config, etc.
                              This file currently gets built automatically by the 
                              manifest_to_fcs_etl_params reactor, based on information in
                              the cytometer-configuration file, though it is likely that
                              this process will need to change as things evolve.
    
    process-control:          A .json file (e.g. process_control.json) specifying some
                              information about bead file, and control files, for each
                              channel. This file gets generated automatically by the 
                              manifest_to_fcs_etl_params reactor, basedon on information
                              in the manifest, plan, and cytometer-configuration files.
    
    junit-directory:          Where the status XML gets written
  
  The steps below must be run in order; much of the work depends on the state of the 
  octave object, which changes with each step.
  '''
  octave = Oct2Py()
  cytometer = Cytometer(args.cytometer_configuration,octave) 
  process = ProcessControl(args.process_control,octave)
  color_model = ColorModel(args.color_model_parameters, args.analysis_parameters, octave,process,cytometer)
  experiment_data = Experiment(args.experimental_data,octave)
  experiment_analysis = Analysis(args.analysis_parameters, args.cytometer_configuration, args.experimental_data, args.color_model_parameters, octave)
  color_model.make_gating(experiment_data)
  color_model.make_color_model()
  experiment_analysis.analyze()

  quicklook = Quicklook(args,experiment_analysis,octave)
  quicklook.make_notebook()


  try:
    os.mkdir(args.junit_directory)
    octave.eval('TASBESession.to_xml(\'{}/TASBESession.xml\')'.format(args.junit_directory))
  except Exception as e:
    logging.error("Error writing JUnit directory {}: {}".format(args.junit_directory, e))


if __name__ == '__main__':
  args = parser.parse_args()
  main(args)
