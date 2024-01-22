# MOT_study
 A Multiple Object Tracking (MOT) task to manipulate attention during speech processing.

MOTmovie.m is the function used by MOT_generate_locations.m to create the moving-dot movies used in the MOT task.
MOT_generate_locations.m is the script used to generate the movies.
MOTtest.m allows the user to test individual MOT movies outside of a full experiment script.

The three 'dw' files together form the full EEG study. The 'ptb_prepare' script sets up some basic PsychToolBox parameters, and the 'ptb_close' script closes it all down and resets the defaults. Both are called within the main 'experiment' script.