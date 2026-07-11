# to-do list

1. ~~Change the diagram on the test results to denote the new approach.~~ Done —
   `ResultCalculator` now derives the reactive threshold from Row 1 (positive
   control) and Row 2 (negative control), and judges Row 3 (the sample) against
   it. `DotGridDisplay` labels the rows accordingly and colours wells from that
   calibrated threshold instead of a fixed cutoff.