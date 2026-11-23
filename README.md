# TB_Excess_USA

matlab code + data for our paper on excess TB incidence in the US during covid (2020-2023), by state, age group and race/ethnicity.

run run_all.m and thats it, all outputs go to results/ (it makes the folder)

- toolbox/ : SubEpiPredict toolbox (original), we used it for the model fits
- output/ : the fits we got from the toolbox for states, age, race. the scripts just read them so no need to refit
- data/ : CDC TB data, predictors (ACS, AtlasPlus HIV, HUD, BJS, gazetteer) and census 2023 population
- make_wide_*.m only build the wide tables from the raw CDC files, run_all doesnt call them

tested on R2024b. needs the statistics toolbox (refitting also needs optimization + global optimization toolboxes)
