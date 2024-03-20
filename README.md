# Speech Processing - MOT study
## A Multiple Object Tracking (MOT) task to manipulate attention during speech processing

MOT_generate_locations.m is the script used to generate the movies used in the MOT task.
MOTmovie.m is the function used by MOT_generate_locations.m to create the movies.
MOTtest.m allows the user to test individual MOT movies outside of a full experiment script.

The three 'dw' files together form the full EEG study. The 'ptb_prepare' script sets up some basic PsychToolBox parameters, and the 'ptb_close' script closes it all down and resets the defaults. Both are called within the main 'experiment' script.

block_rand.m randomises the order of blocks presented to participants during the experiment, creating a Matlab file which is then read by the main experiment script.
The three experimental condition blocks (attend to auditory, attend to visual [high load], attend to visual [low load]) are each shown twice in each session, for a total of 6 blocks per session. Randomisation occurs within each half-session, ensuring that all three blocks are presented before any of the blocks are presented a second time. When participants are asked to ignore the visual task ('attend to auditory') the percetpual load of the visual task presented on screen (number of dots to track) is random for that block, from a choice of high or low load. Whichever load is presented during the first half, the opposite load is always presented in the second half of the session. The script also randomises the order of 6 audiobook chapters played during each of the blocks, with no repeats. When the experiment script is run, it asks for the subject number and block number (out of 6) at the start of the script, and then reads the attention condition, visual task load, and chapter number from the relevant row of the Matlab file.

The code for the visual task is adapted from code kindly provided by [Björn Herrmann](https://github.com/bjornherrmann), originally used in [this](https://www.jneurosci.org/lookup/doi/10.1523/JNEUROSCI.0346-18.2018) paper.
