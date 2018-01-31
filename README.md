# MultiStage.v1
## (Adjusted one-way nesting technique for coastal estuarine modeling in the ADCIRC model)
Multi-stage tool is compiled from developed and existing software components for automating nesting technique in the ADvanced CIRCulation (ADCIRC) model system for high resolution coastal estuarine modeling applications. The tool is developed with the aim of reducing expensive computational cost associated with high resolution modeling using the ADCIR model. The application of the Multi-stage can be more beneficial when the ADCIRC model is coupled to Simulating WAves Nearshore (SWAN) model, or/and domain spin-up run is required for more than couple of days.

The current version supports conventional one-way nesting technique adjusted to the ADCIRC modeling steps requirements. A coarse-resolution outer model communicates to a fine-resolution inner grid (nested grid) through the specification of the open boundary conditions of the fine-resolution grid or High Resolution Limited Area (HRLA) grid. Two-way nesting technique is under development.

First, the coarse-resolution grid simulation is run (stage one) to provide the boundary conditions at the inlets boundaries of the HRLA grid in terms of elevation boundary condition, or/and normal flux boundary condition (not supported yet). Next, the fine-resolution inner (nested) grid or HRLA simulation (stage two) is run forced by boundary conditions (and meteorological forcing). 

Multi-stage outer model is based on ec95 grid with adjusted locations, depths, and resolutions at the open inlets of the major estuaries along the east coast and the Gulf of Mexico. The adjusted ec95 has open Ocean boundary located at longitude 60.041 west expanded to the east coast of the US, the Gulf of Mexico, and the Caribbean Sea. The tool has a comprehensive database of fine-resolution inner model or HRLA grids for most major coastal estuaries along the east coast of the US and the Gulf of Mexico.

In the development of the Multi-stage tool, I take advantage of the exisintg software infrustructures and methods in the ADCIRC Surge Guidance System (ASGS) (https://github.com/jasonfleming/asgs). 
