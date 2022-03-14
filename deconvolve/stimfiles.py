import pandas as pd
import os


class StimfileCreator:
    def __init__(
        self,
        run_files,
        subject,
        stimulus_header,
        timing_header,
    ):
        self.run_files = run_files
        self.subject = subject
        self.stimulus_header = stimulus_header
        self.timing_header = timing_header
        self.runs = list()
        self.stimfiles = list()

        if all([x.endswith(".tsv") for x in self.run_files]):
            self.separator = "\t"
        elif all([x.endswith(".csv") for x in self.run_files]):
            self.separator = ","
        else:
            raise Exception(
                "All files are not correct type. Must be .csv or .tsv")
        print(run_files)

    def create_stimfiles(self):
        print(f"\nCreating stimulus files for subject {self.subject.name}")

        self.__inst_stimfiles()
        self.__add_data_to_stimfiles()

        for stimfile in self.stimfiles:
            print(f"Writing stimulus file: {stimfile.name}")
            stimfile.write_file()

    def __inst_stimfiles(self):
        for run_file in self.run_files:
            # load event timing tsv files
            run_df = pd.read_csv(run_file, sep=self.separator)

            # make new stimfile for each unique task
            for stimulus_type in zip(run_df[self.stimulus_header]):
                # get rid of numbers in string
                stim_string = "".join(
                    i for i in stimulus_type[0] if not i.isdigit())
                stimfile = next(
                    (x for x in self.stimfiles if x.name == stim_string), None
                )
                if stimfile is None:
                    self.stimfiles.append(
                        Stimfile(stim_string, self.subject.deconvolve_dir)
                    )

    def __add_data_to_stimfiles(self):
        # add run timing data to stimfiles
        conditions_list = []
        for run_num, run_file in enumerate(self.run_files, start=1):
            # load event timing tsv files
            run_df = pd.read_csv(run_file, sep=self.separator)

            # add run to each stimfile
            for stimfile in self.stimfiles:
                stimfile.runs.append(Run(run_num))

            # append time to stimfile with associated task
            for row in zip(run_df[self.stimulus_header], run_df[self.timing_header]):
                task_type = "".join(i for i in row[0] if not i.isdigit())
                task_time = row[1]
                stimfile = next(
                    (x for x in self.stimfiles if x.name == task_type), Exception
                )
                stimfile.runs[-1].timing_list.append(task_time)

                # append conditions (cue, time, run)
                conditions_list.append([row[0], row[1], run_num])

            # insert * if no timing for run
            for stimfile in self.stimfiles:
                current_run = stimfile.runs[-1]
                if len(current_run.timing_list) == 0:
                    current_run.timing_list.append("*")

        # create and write conditions df from list generated earlier
        self.condition_df = pd.DataFrame(
            conditions_list,
            columns=["Cue", "Time", "Run"],
        )
        self.condition_df.to_csv(
            os.path.join(self.subject.deconvolve_dir, "conditions.csv"),
            index_label="Index",
        )


class Stimfile:
    def __init__(
        self,
        task_name,
        sub_deconvolve_dir,
    ):
        self.name = task_name
        self.file = f"{task_name}.1D.txt"
        self.filepath = f"{sub_deconvolve_dir}{self.file}"
        self.runs = list()
        self.stimfiles = list()

    def write_file(self):
        with open(self.filepath, "w") as text_file:
            for run in self.runs:
                for event in run.timing_list:
                    text_file.write(f"{str(event)} ")
                text_file.write("\n")
        return


class Run:
    def __init__(self, run_number):
        self.number = run_number
        self.timing_list = list()
