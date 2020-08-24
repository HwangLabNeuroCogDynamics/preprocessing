import sys
import argparse
import glob2
import pandas as pd
import csv
import os
import glob2 as glob

###Constants
DEFAULT_COLUMNS = list()
REGRESSOR_FILE = 'nuisance.1D'
DECONVOLVE_DIR = '3dDeconvolve/'


###Classes
class Stimfile:
    def __init__(self, task_name, sub_deconvolve_dir):
        self.name = task_name
        self.filepath = f"{sub_deconvolve_dir}stim_time_{task_name}.1D.txt"
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


###Functions
def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
    usage="[OPTION] [SUBJECT_DIRECTORY] [COLUMNS_TO_REMOVE]...",
    description="Setup and create files for 3dDeconvolve")

    parser.add_argument('-n','--nodef', action='store_false',
    help="Do not use default columns for removal.")
    parser.add_argument('-c', '--col', nargs='*',
    help="Set columns for removal from regressors .tsv")
    parser.add_argument('dataset_dir',
    help="Base directory of dataset.")
    parser.add_argument('subject',
    help="The subject being analyzed. Do not include sub-.")
    return parser


def parse_regressors(dir, columns_to_remove, subject, sub_deconvolve_dir):
    """Calls append_regressor_files to append each regressor file to combined output.
    Deletes columns specified by user and writes .tsv output file to subject directory."""
    output_df = pd.DataFrame()
    output_df = output_df.append(append_regressor_files(dir, subject))

    for column in columns_to_remove:
        del output_df[column]

    output_filepath = f"{sub_deconvolve_dir}{REGRESSOR_FILE}"
    if os.path.isfile(output_filepath):
        os.remove(output_filepath)
    output_df.to_csv(output_filepath, header=False, sep="\t")


def append_regressor_files(dir, subject):
    """Appends each regressor file to combined output dataframe."""
    output_df = pd.DataFrame()
    files = sorted(glob.glob(f"{dir}*/*{subject}*/**/*regressors.tsv", recursive=True))
    for file in files:
        df = pd.read_csv(file, sep="\t")
        output_df = output_df.append(df)
    return output_df


def find_run_events(dir, subject):
    return sorted(glob.glob(f"{dir}*/*{subject}*/**/*events.tsv", recursive=True))



def inst_stimfiles(sub_deconvolve_dir, run_event_files):
    stimfiles = list()

    for run_file in run_event_files:
        #load event timing tsv files
        run_df = pd.read_csv(run_file, sep='\t')
        for task_type in zip(run_df['trial_type']):
            #make new stimfile for each unique task
            stimfile = next((x for x in stimfiles if x.name == task_type[0]), None)
            if stimfile == None:
                stimfiles.append(Stimfile(task_type[0], sub_deconvolve_dir))
    return stimfiles


def generate_stimfiles(stimfiles, run_event_files):
    #add run timing data to stimfiles
    for run_num, run_file in enumerate(run_event_files, start=1):
        #load event timing tsv files
        run_df = pd.read_csv(run_file, sep='\t')

            #add run to each stimfile
        for stimfile in stimfiles:
            stimfile.runs.append(Run(run_num))

        #append time to stimfile with associated task
        for row in zip(run_df['trial_type'], run_df['onset']):
            task_type = row[0]
            task_time = row[1]
            stimfile = next((x for x in stimfiles if x.name == task_type), Exception)
            stimfile.runs[-1].timing_list.append(task_time)

        #insert * if no timing for run
        for stimfile in stimfiles:
            current_run = stimfile.runs[-1]
            if len(current_run.timing_list) == 0:
                current_run.timing_list.append('*')


###Main
def main():
    parser = init_argparse()
    args = parser.parse_args()

    #if default columns option true, add default columns for removal
    if not args.nodef:
        args.col.append(DEFAULT_COLUMNS)

    deconvolve_dir = f"{args.dataset_dir}{DECONVOLVE_DIR}"
    if not os.path.isdir(deconvolve_dir):
        os.mkdir(deconvolve_dir)
    sub_deconvolve_dir = f"{deconvolve_dir}sub-{args.subject}/"
    if not os.path.isdir(sub_deconvolve_dir):
        os.mkdir(sub_deconvolve_dir)

    #regressors parsing
    parse_regressors(args.dataset_dir, args.col, args.subject, sub_deconvolve_dir)

    #creating stim_times
    run_event_files = find_run_events(args.dataset_dir, args.subject)
    stimfiles = inst_stimfiles(sub_deconvolve_dir, run_event_files)
    generate_stimfiles(stimfiles, run_event_files)

    for stimfile in stimfiles:
        stimfile.write_file()

main()
