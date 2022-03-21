# GeoSensor network optimisation and evaluation tool to support decisions at multiple scales
Code and Data supporting the proposal to the BBSRC Molecules to Landscape call (March 2022)

## Summary
This project proposes a process agnostic, parsimonious approach to sample design. Sample suitability and configurations are evaluated using locally adapted ordinary kriging with an interpolation variance (OKIV) [1], where local variance provides a measure of the value of sampling at potential locations. Previous work has shown that detailed process model outputs can be approximated by underlying environmental gradients [2] and error (kriged variance) for a given soil process at sample locations can be approximated from underlying environmental gradients (slope and soil permeability).

This spatial sampling strategy minimises the OKIV weighted distances. Sample location optimality conceptualised in this way underpins the evaluation function used in the optimisation. Thus sets of sample locations are identified that are sensitive to local environmental gradient variance, over different spatial extents representing different scales of decision-making.

A scale-sensitive evaluation function calculates the OKIV from the environmental gradients at any current and proposed sample locations. A search heuristic (eg GAs, GGAs, p-median, Pareto MCO, etc) is used to identify sets of n that are optimal at different scales. Operationally this follows [3]. 

The method will be evaluated using point process methodologies [see 4] to compare the optimal sample configurations generated from underlying environmental gradients (ie independent of measurement) with those generated from North Wyke Farm Platform (NWFP) measured data. The NWFP has 3 instrumented farms, in situ sensors and detailed,. extensive soil process datasets. Evaluations will incorporate different sample sizes, measured and simulated data conditioned by measured data. 

## References
[1] Yamamoto https://doi.org/10.1023/A:1007577916868 \
[2] Comber https://doi.org/10.3389/fsufs.2019.00042 \
[3] Brus https://doi.org/10.1016/j.geoderma.2018.07.036 \\
[4] Fuentes-Santos https://doi.org/10.1080/03610918.2021.1901118 \\
