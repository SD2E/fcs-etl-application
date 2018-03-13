# Optimization Notes

Because it's a complex environment that knits together multiple runtimes + 
sophisticated Python code, the fcs-etl-application container can have some
painfully long run times, and it's also a bear to push to DockerHub because
it generates a lot of layers. 

## Baseline Performance

* Docker runtime:
    * Version 18.02.0-ce, build fc4de44
    * CPUs: 4
    * RAM: 2 GB
* Host Specs:
    * OS: MacOS X 10.12.6
    * Model: MacBookPro11,5
    * Processor
        * Name: Intel Core i7
        * Speed: 2.5 GHz
        * Total Cores: 4
    * Memory
        * 2x 8 GB DDR3 RAM 1600 Mhz
* Network:
    * 365 Mbps down / 380.8 Mbps up

```shell
$ time docker build --no-cache -t sd2e/fcs:optimize .
Successfully built 70659799d467
Successfully tagged fcs:dev

real    7m21.246s
user    0m0.560s
sys 0m0.359s

$ time docker push sd2e/fcs:optimize

real    1m43.977s
user    0m0.219s
sys 0m0.116s
```

## Order of Operations

1. octave repo added before the update/install.
2. octave needs to be installed before TASBE
3. Numpy and SciPy need to be installed via apt
3. TASBE should be updated as frequently as the python code


