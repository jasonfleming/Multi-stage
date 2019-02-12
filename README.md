# Seven-member ensemble high-resolution estuarine forecast system known as Ensemble-Multistage
## (Adjusted one-way nesting technique for coastal estuarine modeling in the ADCIRC model)

<p align="center">
  <img src="https://github.com/ptaeb2014/Multi-stage/blob/master/graphic.jpg">
</p>

MultiStage tool is compiled from developed and existing software components for automating nesting technique in the ADvanced CIRCulation (ADCIRC) model system for high-resolution coastal estuarine modeling. The tool is developed with the aim of reducing expensive computational cost of with high-resolution ADCIRC modeling, and improving the forecast skill by performing ensemble approach and providing probabilistic solutions.

The current version supports conventional one-way nesting technique applied in the ADCIRC model. A large-scale coarse-resolution model communicates to a fine-scale high-resolution model through the specification of the open boundaries of the fine-resolution mesh. Nearshore predictions are made by the large-scale coarse and estuarine predictions are made by the fine-scale high-reosluion mesh runs.

The core model, the ADCIRC+SWAN model, is forced by seven wind forcing per cycle. Wind forcings include deterministic North American Meso-scale Model (NAM), ensemble mean, ensemble mean + 1 standard deviation, and ensemble mean - 1 standard deviation of Short Range Regional Ensemble Forecast (SREF) and ensemble mean, ensemble mean + 1 standard deviation, and ensemble mean - 1 standard deviation of Global Ensemble Forecast System (GEFS).

In the development of the Multi-stage tool, I take advantage of the existing software infrastructures and methods in the ADCIRC Surge Guidance System (ASGS) (https://github.com/jasonfleming/asgs).

