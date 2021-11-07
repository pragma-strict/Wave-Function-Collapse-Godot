# Wave-Function-Collapse-Godot
Testing out one of the coolest procedural generation algorithms ever!

![Screenshot](https://github.com/pragma-strict/Wave-Function-Collapse-Godot/blob/master/Images/screenshot2.png)


## A quick summary of the wavefunction collapse algorithm.
Entropy is the number of possible options for a given cell. The output grid starts with maximum entropy (all options are available) and throughout the execution of the algorithm each cell is reduced to an entropy of 1 i.e. its type is chosen.
This is accomplished by:
1. Pick a location in the output grid to "collapse" (choose its state and reduce its entropy to 1)
2. Propogate effects of the collapse throughout the rest of the grid. Since cells are constrained by the states of their neighbors, the entropy of some neighboring cells will also be reduced. 
3. Choose a cell with the lowest entropy as the next cell to collapse. It is possible for the algorithm to fail if two incompatible cell types are forced to be neighbors. Choosing cells with low entropy on this step helps to prevent this failure.

