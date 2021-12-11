# PlexonPL2_to_DAT_and_SMRx_converter

What it is: MATLAB script

What it does: converts Plexon's .pl2 files into binary .dat and Cambridge Electonics Design .SMRx files.

What it does in details:
  1. Gets data from Plexon .pl2 file
  2. Optionally (see comments in the code) filters the signal (Butterworth 4th order band-pass 300-7500Hz)
  3. Optionally (see comments in the code) subtracts from signal on each MEA channel
      the mean or median (You choose) of: signals on whole MEA or signals on one shank of MEA (the one where the channel is).
  5. Writes processed signals to binary .DAT file and CED .SMRX file

Remarks:
  - only wideband (optionally processed) channels are written to binary .DAT file
  - wideband (optionally processed), auxiliary input and event channels are written to .SMRX file

