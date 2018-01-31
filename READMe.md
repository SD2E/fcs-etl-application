
# FCS-ETL Reactor

This application processes batches of flow cytometry reads from the SD2 program and allows
users to choose an output data frame that best suits their needs.

## Parameterization

This application uses five required parameters that are used as inputs.

_[analysis-parameters](#ap)_  A .json file (e.g. analysis_parameters.json) specifying some information about the analyses to be performed, the parameters
of these analyses, input/output locations of files, etc. If
reanalysis of the same data set is being performed, this is
generally the file that will be changed (most likely by TA1).
Currently, this gets built automatically by the
manifest_to_fcs_etl_params reactor, based on some assumptions
about default values.

_[cytometer-configuration](#cc)_  A .json file (e.g. cytometer_configuration.json) describing the state of the cytometer used to collect the data. This
file will generally be provided by the TA3 performer, and
will tend to change infrequently (if at all).

_experimental-data_  A .json file (e.g. experimental_data.json) describing the URI
and file locations for the raw data files to be included.
This file gets generated automatically by the
manifest_to_fcs_etl_params reactor, based on the manifest.

_[color-model-parameters](#cm)_   A .json file (e.g. color_model_parameters.json) describing the
species being analyzed, channels, bead peak config, etc.
his file currently gets built automatically by the
manifest_to_fcs_etl_params reactor, based on information in
the cytometer-configuration file, though it is likely that
this process will need to change as things evolve.

_process-control_ A .json file (e.g. process_control.json) specifying some
information about bead file, and control files, for each
channel. This file gets generated automatically by the
manifest_to_fcs_etl_params reactor, basedon on information
in the manifest, plan, and cytometer-configuration files.

An additional optional parameter is:
    _--junit-directory:_          Where the status XML gets written


## Parameterization Objects
This section will touch on the elements within the paramter files that may be commonly editted by performers in the SD2 program.

###  <a name="ap">Analysis Parameters</a>

```
{
	"_comment1": "Information linking experiment FCS files to the appropriate cytometer channels, to be supplied by TA1/TA2",
	"tasbe_analysis_parameters": {
		"_comment1": "the rdf:about field is a URI that persistently identifies this analysis configuration",
		"rdf:about": "http://bbn.com/TASBE/Examples/WeissLab/ND/2012-03-12/Run1/Analysis1",

		"_comment2": "Compatible TASBE interface version, following Semantic Versioning (semver.org).  Note that underspecifying version allows use of backward compatible upgrades.",
		"tasbe_version": "https://github.com/SD2E/reactors-etl/releases/tag/2",

		"_comment3": "identifier linking to the color model for interpreting units.  Should typically be derived from the same process_control_data as is referenced in the experimental_data",
		"color_model": "http://bbn.com/TASBE/Examples/WeissLab/ND/2012-03-12/Run1/Colormodel",

		"_comment4": "identifier linking to the data collection to analyze",
		"experimental_data": "http://mit.edu/Examples/WeissLab/ND/2012-03-12/Run1/ExperimentalData",

		"_comment6": "additional configuration parameters",
		"output": {
			"title": "sample_run",
			"_comment7": "set plots for additional face validity information",
			"plots": true,
			"_comment8": "set the location for plots",
			"plots_folder": "plots",
			"_comment10": "set plots for additional face validity information",
			"output_folder": "output",
			"file": "output/output.csv",
			"quicklook": true,
			"quicklook_folder": "quicklook"
		},
                "channels": ["mKate", "EYFP","EBFP2"],
		"_comment7": "additional parameters controlling data processing and output; type can be bin_counts or point_clouds",
		"min_valid_count": 100,
		"pem_drop_threshold": 5,

        "_comment8": "Supported output modalities. histogram reports bin centers and counts. point_cloud reports each particle for an fcs file in seperate files. bayesdb_files
         produces a dataframe for the bayesdb that outlines the metadata and particle files.",
        "additional_outputs": ["histogram", "point_clouds", "bayesdb_files"],


        "_comment9": "If the histogram output is selected, this ",
        "bin_min": 6,
		"bin_max": 10,
		"bin_width": 0.1
	}
```

### <a name="cc">Cytometer Configuration</a>

This file describes the instrument configuration. An annotated snippet of this information is provided:

```
{
	"_comment1" : "Persistent information about a flow cytometer, to be supplied by TA3",
	"tasbe_cytometer_configuration": {
		"_comment1": "the rdf:about field is a URI that persistently identifies this instrument and optical configuration",
		"rdf:about": "http://mit.edu/WeissLab/Cytometer1/Config2011-Jan-01",

		"_comment2": "Compatible TASBE interface version, following Semantic Versioning (semver.org).  Note that underspecifying version allows use of backward compatible upgrades.",
		"tasbe_version": "https://github.com/SD2E/reactors-etl/releases/tag/2",

		"_comment3": "the channels list all of the parameters of interest in an FCS file from the instrument",
		"channels": [{
				"_comment1": "name must exactly match the channel name in the FCS files",
				"name": "FITC-A",
				"_comment2": "excitation is the channel laser; these examples show the recommended values",
				"excitation_wavelength": 488,
				"_comment3": "emission_filter is the channel optical filter; these examples show the recommended values",
				"emission_filter": {
					"type": "bandpass",
					"center": 530,
					"width": 30
				},
				"_comment4": "emission_filter can also be of type 'longpass', which has cutoff instead of center and width"
			},
			{
				"name": "PE-Tx-Red-YG-A",
				"excitation_wavelength": 561,
				"emission_filter": {
					"type": "bandpass",
					"center": 610,
					"width": 20
				}
			},
			{
				"name": "Pacific Blue-A",
				"excitation_wavelength": 405,
				"emission_filter": {
					"type": "bandpass",
					"center": 450,
					"width": 50
				}
			},
			{
				"name": "FSC-A",
				"excitation_wavelength": 488,
				"emission_filter": {
					"type": "bandpass",
					"center": 488,
					"width": 10
				}
			},
			{
				"name": "SSC-A",
				"excitation_wavelength": 488,
				"emission_filter": {
					"type": "bandpass",
					"center": 488,
					"width": 10
				}
			}
		]
	}
}
```

###  <a name="cm">Color Model</a>

```
{
	"_comment1": "Parameters controlling conversion of process controls into an ERF color model, plus debugging/graphical outputs, to be supplied by TA1/TA2",
	"tasbe_color_model_parameters": {
		"_comment1": "the rdf:about field is a URI that persistently identifies this run configuration",
		"rdf:about": "http://bbn.com/TASBE/Examples/WeissLab/ND/2012-03-12/Run1/Colormodel",

		"_comment2": "Compatible TASBE interface version, following Semantic Versioning (semver.org).  Note that underspecifying version allows use of backward compatible upgrades.",
		"tasbe_version": "https://github.com/SD2E/reactors-etl/releases/tag/2",

		"_comment3": "identifier linking to the process control data set to be run",
		"process_control_data": "http://mit.edu/WeissLab/ND/2012-03-12/Run1/Controls",

		"_comment4": "For each channel, the species and how to process and display it",
		"channel_parameters": [{
				"_comment1": "name must match a channel from the cytometer configuration",
				"name": "FITC-A",
				"_comment2": "a persistent URI linking to the actual species being quantified",
				"species": "https://www.ncbi.nlm.nih.gov/protein/AMZ00011.1",
				"_comment3": "Nickname for the species for charts",
				"label": "EYFP",
				"_comment4": "cutoff for analysis",
				"min": 2,
				"_comment5": "primary color for lines on certain plots",
				"chart_color": "y"
			},

			{
				"name": "PE-Tx-Red-YG-A",
				"species": "https://www.ncbi.nlm.nih.gov/protein/3BXC_H",
				"label": "mKate",
				"min": 2,
				"chart_color": "r"
			},
			{
				"name": "Pacific Blue-A",
				"species": "https://www.ncbi.nlm.nih.gov/protein/AMZ00018.1",
				"label": "EBFP2",
				"min": 2,
				"chart_color": "b"
			}
		],

		"_comment5": "Other processing parameters, to be exposed",
		"tasbe_config": {
			"gating": {
				"type": "auto",
				"k_components": 2
			},
			"autofluorescence": {
				"type": "placeholder"
			},
			"compensation": {
				"type": "placeholder"
			},
			"beads": {
				"type": "placeholder"
			}
		},

		"_comment6": "Cutoff for bead peak detection",
		"bead_min": 2,

		"_comment7": "Which channel is being used for unit calibration",
		"ERF_channel_name": "FITC-A",

		"_comment8": "additional parameters controlling data processing and output",
		"translation_plot": false,
		"noise_plot": false
	}
}
```


### To deploy
`sh deploy.sh fcs-etl-0.3.1 fcs-etl-0.3.1/fcs-etl-app.json`