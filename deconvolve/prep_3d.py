import pandas as pd
import settings as s
from lib import common
import sys


# Classes
class Stimfile:
    def __init__(self, task_name, sub_deconvolve_dir):
        self.name = task_name
        self.filepath = f"{sub_deconvolve_dir}{task_name}.1D.txt"
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


# Functions
def parse_regressors(dataset_dir, columns, use_def_columns=True):
    """Appends specified columns from regressor files and writes combined output file.
    Input: Subject (subject object), [Columns (str)]"""
    dir_tree = common.DirectoryInfo(dataset_dir)
    subjects = common.get_subjects(dir_tree)
    if use_def_columns:
        columns.extend(s.DEFAULT_COLUMNS)

    for subject in subjects:
        parse_sub_regressors(subject, columns)


def parse_sub_regressors(subject, columns):
    """Appends specified columns from regressor files and writes combined output file.
    Input: Subject (subject object), Columns (list str)"""
    print(f'Parsing regressor files for subject {subject}')

    output_filepath = subject.deconvolve_dir + s.REGRESSOR_FILE
    output_df = pd.DataFrame()
    output_censor = []
    files = common.get_ses_files(subject.sessions,
                                 f"{subject.fmriprep_dir}{s.SESSION}/{s.FUNC_DIR}*{s.REGRESSOR_WC}")

    print(f'Extracting columns {columns} from regressor files')
    for file in files:
        print(file)
        df = pd.read_csv(file, sep="\t")
        output_df = output_df.append(df[columns])
        output_censor.extend(censor_motion(df))

    print(output_filepath)
    output_df.to_csv(output_filepath, header=False, index=False, sep="\t")
    with open(subject.deconvolve_dir + s.CENSOR_FILE, 'w') as file:
        for num in output_censor:
            file.writelines(f'{num}\n')


def censor_motion(df):
    censor_vector = list()
    prev_motion = None

    print('Censoring motion')
    for index, row in enumerate(zip(df['framewise_displacement'])):
        if row[0] > 0.2:
            print(f'{index} {row[0]}')
            censor_vector.append(0)
            prev_motion = index
        elif prev_motion is not None and (prev_motion + 1 == index or prev_motion + 2 == index):
            print(f'{index} {row[0]}')
            censor_vector.append(0)
        else:
            censor_vector.append(1)

    return censor_vector


def create_stimfiles(subject):
    print(f'Creating stimulus files for subject {subject}')

    files = list()
    files = common.get_ses_files(subject.sessions,
                                 f"{subject.bids_dir}{s.SESSION}/{s.FUNC_DIR}*{s.EVENTS_WC}")

    stimfiles = inst_stimfiles(subject.deconvolve_dir, files)
    generate_stimfiles(stimfiles, files)

    for stimfile in stimfiles:
        stimfile.write_file()


def inst_stimfiles(sub_deconvolve_dir, run_event_files):
    stimfiles = list()

    for run_file in run_event_files:
        # load event timing tsv files
        run_df = pd.read_csv(run_file, sep='\t')
        for task_type in zip(run_df['trial_type']):
            # make new stimfile for each unique task
            stimfile = next(
                (x for x in stimfiles if x.name == task_type[0]), None)
            if stimfile is None:
                stimfiles.append(Stimfile(task_type[0], sub_deconvolve_dir))
    return stimfiles


def generate_stimfiles(stimfiles, run_event_files):
    # add run timing data to stimfiles
    for run_num, run_file in enumerate(run_event_files, start=1):
        print(run_file)
        # load event timing tsv files
        run_df = pd.read_csv(run_file, sep='\t')

        # add run to each stimfile
        for stimfile in stimfiles:
            stimfile.runs.append(Run(run_num))

        # append time to stimfile with associated task
        for row in zip(run_df['trial_type'], run_df['onset']):
            task_type = row[0]
            task_time = row[1]
            stimfile = next(
                (x for x in stimfiles if x.name == task_type), Exception)
            stimfile.runs[-1].timing_list.append(task_time)

        # insert * if no timing for run
        for stimfile in stimfiles:
            current_run = stimfile.runs[-1]
            if len(current_run.timing_list) == 0:
                current_run.timing_list.append('*')


if __name__ == '__main__':
    globals()[sys.argv[1]](sys.argv[2])
