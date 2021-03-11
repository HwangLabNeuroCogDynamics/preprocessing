import pandas as pd
import settings as s
import common
import basic_settings as bs
import os
import argparse
import warnings
import numpy as np
import glob as glob

# Classes
class Stimfile:
    def __init__(self, task_name, sub_deconvolve_dir):
        self.name = task_name
        self.file = f'{task_name}.1D.txt'
        self.filepath = f"{sub_deconvolve_dir}{self.file}"
        self.runs = list()

    def write_file(self):
        with open(self.filepath, "w") as text_file:
            for run in self.runs:
                for event in run.timing_list:
                    text_file.write(f"{str(event)} ")
                text_file.write('\n')
        return


class Run:
    def __init__(self, run_number):
        self.number = run_number
        self.timing_list = list()


def parse_regressors(subject, columns, censor, parse_regressors, threshold):
    """Appends specified columns from regressor files and writes combined output
     file. Input: Subject (subject object), Columns (list str)"""
    regressor_filepath = subject.deconvolve_dir + s.REGRESSOR_FILE
    censor_filepath = subject.deconvolve_dir + s.CENSOR_FILE
    output_censor = []
    output_df = pd.DataFrame()

    if not os.path.exists(subject.deconvolve_dir):
        os.makedirs(subject.deconvolve_dir)
    elif os.path.exists(regressor_filepath) and not parse_regressors:
        print(f'\n\nSkipping: Subject {subject.name} already has nuisance '
        'regressor file. To overwrite use the -parse_regressors flag.')
    else:
        print(f'\n\nParsing regressor files for subject {subject.name} in '
        f'{subject.deconvolve_dir}')
        parse_regressors = True

    # censor if censor file does not exist
    if os.path.exists(censor_filepath) and not censor:
        print('''Skipping: Subject already has censoring.''')
    else:
        censor = True

    if not parse_regressors and not censor:
        return

    files = common.get_ses_files(subject, subject.fmriprep_dir, s.REGRESSOR_WC)
    if not files:
        warnings.warn(f'Subject {subject.name} has no regressor files')
        return
    for file in files:
        print(f'Parsing: {file.split("/")[-1]}')
        df = pd.read_csv(file, sep="\t")
        output_df = output_df.append(df[columns])
        if censor:
            output_censor.extend(censor_motion(df, threshold=threshold))


    print(f'Writing regressor file to {regressor_filepath}')
    output_df.to_csv(regressor_filepath, header=False,
                     index=False, sep="\t")

    print(f'Writing censor file to {censor_filepath}')
    with open(censor_filepath, 'w') as file:
        for num in output_censor:
            file.writelines(f'{num}\n')
    print(f'\n\nSuccessfully extracted columns {columns} from regressor files '
          'and censored motion')


def censor_motion(df, threshold=0.2):
    censor_vector = []
    prev_motion = None

    for index, row in enumerate(zip(df['framewise_displacement'])):
        # censor first three points
        if index < 3:
            censor_vector.append(0)
            continue

        if row[0] > threshold:
            censor_vector.append(0)
            prev_motion = index
        elif prev_motion is not None and (prev_motion + 1 == index or prev_motion + 2 == index):
            censor_vector.append(0)
        else:
            censor_vector.append(1)

    percent_censored = round(censor_vector.count(0) / len(censor_vector) * 100)
    print(
        f'\tCensored {percent_censored}% of points')
    return censor_vector


def create_stimfiles(subject, run_file_dir, stimulus_header, timing_header,
                     file_WC):
    print(f'\nCreating stimulus files for subject {subject.name}')

    files = common.get_ses_files(subject, run_file_dir, file_WC)
    print(f'Run data files: {files}\n')

    if all([x.endswith('.tsv') for x in files]):
        seperator = '\t'
    elif all([x.endswith('.csv') for x in files]):
        seperator = ','
    else:
        raise Exception('All files are not correct type. Must be .csv or .tsv')

    stimfiles = inst_stimfiles(subject.deconvolve_dir, stimulus_header, files,
                               seperator)
    generate_stimfiles(stimfiles, files, stimulus_header, timing_header,
                       seperator)

    for stimfile in stimfiles:
        print(f'Writing stimulus file: {stimfile.name}')
        stimfile.write_file()

    return stimfiles

def inst_stimfiles(deconvolve_dir, stimulus_header, run_files, seperator):
    stimfiles = list()

    for run_file in run_files:
        # load event timing tsv files
        run_df = pd.read_csv(run_file, sep=seperator)

        # make new stimfile for each unique task
        for stimulus_type in zip(run_df[stimulus_header]):
            # get rid of numbers in string
            stim_string = ''.join(i for i in stimulus_type[0] if not i.isdigit())
            stimfile = next((x for x in stimfiles if x.name == stim_string), None)
            if stimfile is None:
                stimfiles.append(Stimfile(stim_string, deconvolve_dir))
    return stimfiles


def generate_stimfiles(stimfiles, run_files, stimulus_header, timing_header,
                       seperator):
    # add run timing data to stimfiles
    for run_num, run_file in enumerate(run_files, start=1):
        # load event timing tsv files
        run_df = pd.read_csv(run_file, sep=seperator)

        # add run to each stimfile
        for stimfile in stimfiles:
            stimfile.runs.append(Run(run_num))

        # append time to stimfile with associated task
        for row in zip(run_df[stimulus_header], run_df[timing_header]):
            task_type = ''.join(i for i in row[0] if not i.isdigit())
            task_time = row[1]
            stimfile = next(
                (x for x in stimfiles if x.name == task_type), Exception)
            stimfile.runs[-1].timing_list.append(task_time)

        # insert * if no timing for run
        for stimfile in stimfiles:
            current_run = stimfile.runs[-1]
            if len(current_run.timing_list) == 0:
                current_run.timing_list.append('*')
