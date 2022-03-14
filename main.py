from thalpy import base, regressors
from thalpy.constants import paths, wildcards

import os
import argparse
import subprocess
from lib import bashwriter
from deconvolve import stimfiles, qsub_3d
from fmriprep import qsub_fmriprep
from FD_stats import motion
import settings as s
import getpass
import numpy as np
import math
import socket
import zipfile
import sys
import glob as glob
import pandas as pd


def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run pre-processing on whole dataset or selected subjects",
        usage="[DATASET_DIR] [SUBCOMMANDS [OPTIONS]]",
        add_help=False,
    )

    # Required arguments
    required = parser.add_argument_group("Required Arguments")
    required.add_argument("dataset_dir", help="Base directory of dataset.")

    required.add_argument(
        "-h", "--help", action="help", help="show this help message and exit"
    )

    # Optional arguments
    subs = argparse.ArgumentParser(add_help=False)
    subs_group = subs.add_argument_group("Subject arguments")
    subs_group.add_argument(
        "-n",
        "--numsub",
        type=int,
        help="""The number of subjects being analyzed. If none
                                        listed, default will be whole dataset (minus completed subjects)""",
    )
    subs_group.add_argument(
        "-s",
        "--subjects",
        nargs="*",
        help="""The subjects being analyzed. Do not include
                             sub- prefix. If subjects are not included,
                             pre-processing will be run on whole dataset (minus completed subjects) by default
                             or on number of subjects given via the --numsub flag""",
    )

    dirs = argparse.ArgumentParser(add_help=False)
    dirs_grp = dirs.add_argument_group("Path arguments")
    dirs_grp.add_argument(
        "--bids_dir",
        help="Path for bids directory if not located in " "dataset directory.",
    )
    dirs_grp.add_argument(
        "--work_dir",
        help="""The working dir for programs. Default for argon
                          is user dir in localscratch. Default for thalamege is
                          work directory in dataset directory.""",
    )

    general = argparse.ArgumentParser(add_help=False)
    gen = general.add_argument_group("General Optional Arguments")
    gen.add_argument(
        "--rerun_mem",
        action="store_true",
        default=False,
        help="Rerun subjects that failed due to memory constraints",
    )
    gen.add_argument(
        "--slots",
        type=int,
        help="""Set number of slots/threads per subject. Default
                            is 4.""",
        default=4,
    )

    argon = argparse.ArgumentParser(add_help=False)
    argon_group = argon.add_argument_group("Argon HPC Optional Arguments")
    argon_group.add_argument(
        "--email", action="store_true", help="Receive email notifications from HPC"
    )
    argon_group.add_argument(
        "--no_qsub",
        default=True,
        action="store_false",
        dest="is_qsub",
        help="Does not submit generated bash scripts.",
    )

    argon_group.add_argument(
        "--hold_jid",
        help="""Jobs will be placed on hold until specified job
                             completes. [JOB_ID]""",
    )
    argon_group.add_argument(
        "--no_resubmit",
        action="store_true",
        default=False,
        help="""Enable to not resubmit tasks after migration.
                            Default is to resubmit.""",
    )
    argon_group.add_argument("--mem", help="Set memory for HPC")
    argon_group.add_argument("-q", "--queue", help="Set queue for HPC")
    argon_group.add_argument(
        "--stack",
        nargs=2,
        help="""Queue jobs in dependent stacks. When all jobs
                            complete, next will start. Two required integer
                            arguments [# of stacks][# of jobs per stack]. Use
                            'split' in second argument to split remaining jobs
                            evenly amongst number of stacks.""",
    )

    subparsers = parser.add_subparsers(
        title="Subcommands", required=True, dest="subcommand"
    )

    heudiconv_parser = subparsers.add_parser(
        s.HEUDICONV,
        parents=[subs, dirs],
        usage="[SCRIPT_PATH][OPTIONS]",
        help="""Convert raw data files to
                                                 BIDS format. Conversion script
                                                 filepath is required.""",
    )
    heudiconv_parser.add_argument(
        "script_path",
        help="""Filename of script. Script must be
                                      located in following directory:
                                      /data/backed_up/shared/bin/heudiconv/heuristics/""",
    )
    heudiconv_parser.add_argument(
        "--post_conv_script",
        help="""Filepath of post-heudiconv Conversion
                                  script. Ocassionally needed to make further
                                  changes after running heudiconv.""",
    )

    mriqc_parser = subparsers.add_parser(
        s.MRIQC,
        parents=[subs, dirs, general, argon],
        usage="[OPTIONS]",
        help="""Run mriqc on dataset to analyze
                                             quality of data.""",
    )
    mriqc_parser.add_argument(
        "--group",
        action="store_true",
        help="""Run group analysis for mriqc instead of default
                                participant level""",
    )
    mriqc_parser.add_argument(
        "--mriqc_opt",
        help="""Options to add to mriqc. Write between \'\' as
                               shown: \'--[OPTION1] --[OPTION2] ...\'""",
    )

    fmriprep_parser = subparsers.add_parser(
        s.FMRIPREP,
        parents=[subs, dirs, general, argon],
        usage="[OPTIONS]",
        help="""Preprocess data with
                                                fmriprep pipeline.""",
    )
    fmriprep_parser.add_argument(
        "--fmriprep_opt",
        help="""Options to add to fmriprep. Write between \'\'
                              and replace - with * as shown: \'**[OPTION1] arg1 ** [OPTION2] ...\'""",
    )

    deconvolve_parser = subparsers.add_parser(
        s.DECONVOLVE,
        parents=[subs, dirs, general, argon],
        usage="[stimulus_col][timing_col][OPTIONS]",
        help="""Parse regressor files, censor motion, create stimfiles, and run 3dDeconvolve.""",
    )
    deconvolve_parser.add_argument(
        "stimulus_col",
        help="""Column name for stimulus type in
                                    run timing file.""",
    )
    deconvolve_parser.add_argument(
        "timing_col",
        help="""Column name for time of stimulus
                                   presentation in run timing file.""",
    )
    deconvolve_parser.add_argument(
        "--bold_wc",
        default="*bold.nii.gz",
        help="""Wildcard used to find bold files using glob. Must have * at beggining.
                                   Default is *""",
    )
    deconvolve_parser.add_argument(
        "--timing_file_dir",
        help="""Directory holding run timing files.
                                   Default is dataset BIDS directory.""",
    )
    deconvolve_parser.add_argument(
        "--run_timing_wc",
        default="*",
        help="""Wildcard used to find run timing
                                   files using glob. Must have * at beggining.
                                   Default is *""",
    )
    deconvolve_parser.add_argument(
        "--regressors_wc",
        default=wildcards.REGRESSOR_WC,
        help=f"""Wildcard used to find regressors
                                   files using glob. Must have * at beggining.
                                   Default is {wildcards.REGRESSOR_WC}.""")
    deconvolve_parser.add_argument(
        "--use_stimfiles",
        default=False,
        action="store_true",
        help="""Use stimfiles instead of stim config
                                   for setting up 3dDeconvolve script.""",
    )
    deconvolve_parser.add_argument(
        "-c",
        "--columns",
        default=[],
        nargs="*",
        dest="columns",
        help="""Enter columns to parse from
                                          regressors file into nuisance.1D file for
                                          usage in 3dDeconvolve. Default columns
                                          will be added automatically.""",
    )
    deconvolve_parser.add_argument(
        "--no_default",
        default=False,
        action="store_true",
        help=f"""Enter flag to not use default
                                          columns. If not entered, default columns
                                          will be parsed. Default columns are:
                                          {s.DEFAULT_COLUMNS}""",
    )
    deconvolve_parser.add_argument(
        "--sessions",
        nargs="*",
        help="""Set the sessions to be analyzed in order.
                                          Default will be all sessions in alphabetical
                                          order""",
    )
    deconvolve_parser.add_argument(
        "--threshold",
        default=0.2,
        type=float,
        help="""Threshold for censoring. Default is 0.2""",
    )

    regressors_parser = subparsers.add_parser(
        s.REGRESSORS,
        parents=[subs, dirs],
        usage="[OPTIONS]",
        help="""Parse regressor files to extract columns and censor motion.""",
    )
    regressors_parser.add_argument(
        "--regressors_wc",
        default=wildcards.REGRESSOR_WC,
        help=f"""Wildcard used to find regressors
                                   files using glob. Must have * at beggining.
                                   Default is {wildcards.REGRESSOR_WC}.""",
    )
    regressors_parser.add_argument(
        "-c",
        "--columns",
        default=[],
        nargs="*",
        dest="columns",
        help="""Enter columns to parse from
                                          regressors file into nuisance.1D file for
                                          usage in 3dDeconvolve. Default columns
                                          will be added automatically.""",
    )
    regressors_parser.add_argument(
        "--no_default",
        default=False,
        action="store_true",
        help=f"""Enter flag to not use default
                                          columns. If not entered, default columns
                                          will be parsed. Default columns are:
                                          {s.DEFAULT_COLUMNS}""",
    )
    regressors_parser.add_argument(
        "--threshold",
        default=0.2,
        type=float,
        help="""Threshold for censoring. Default is 0.2""",
    )

    mema_parser = subparsers.add_parser(
        "3dmema",
        parents=[subs, dirs, general, argon],
        usage="[STARTING_INDEX][ENDING_INDEX][OPTIONS]",
        help="""Runs 3dmema.""",
    )
    mema_parser.add_argument(
        "starting_index", default=2, type=int, help="""""")
    mema_parser.add_argument("ending_index", type=int, help="""""")

    fd_stats_parser = subparsers.add_parser(
        "FD_stats",
        parents=[subs, dirs],
        usage="[OPTIONS]",
        help="""Calculates FD statistics
                                            for dataset. Outputs csv with %% of
                                            points over FD threshold anbd FD
                                            mean for each run and subject.""",
    )

    fd_stats_parser.add_argument(
        "--threshold",
        default=0.2,
        type=float,
        help="""Threshold for FD motion. Default is 0.2""",
    )
    fd_stats_parser.add_argument(
        "--sessions",
        nargs="*",
        help="""Set the sessions to be analyzed in order.
                                          Default will be all sessions in alphabetical
                                          order""",
    )

    return parser


def get_subjects(process, args, dir_tree, completed_subs, numsub=None):
    """Based on args specficiations, returns list of subjects in dataset.

    If numbsub is None, all subjects will be returned. Otherwise, will return
    numsub subjects.

    Parameters
    - ---------
    process: string
        String denoting the current process
    args: type
        Command line arguments parsed by ArgumentParser
    dir_tree: DirectoryTree
        Class that contains general path info for dataset
    completed_subs: [str]
        List of completed subjects found in completed_subjects.txt
    numsub: int
        Number of subjects to get

    Returns
    - ------
    [Subject]
        List of subjects in dataset

    """
    # set directory from which to get subjects
    if process == s.FMRIPREP or process == s.MRIQC:
        sub_dir = dir_tree.bids_dir
    elif process in [s.DECONVOLVE, s.FD_STATS, s.REGRESSORS]:
        sub_dir = dir_tree.fmriprep_dir

    subjects = base.Subjects()

    if hasattr(args, "rerun_mem") and args.rerun_mem:
        subjects = base.read_file_subargs(
            dir_tree.process_dir + paths.LOGS_DIR + s.FAILED_SUB_MEM_FILE,
            dir_tree,
            num=numsub,
        )
        args.slots = 20
        if not args.mem:
            args.mem = "mem_256G=true"

    elif process == s.HEUDICONV:
        subjects = get_raw_subjects(
            dir_tree, excluded=completed_subs, num=numsub)
        #
    elif args.subjects is None:
        subjects = base.get_subjects(
            sub_dir, dir_tree, excluded=completed_subs, num=numsub
        )
    # subjects entered in command line
    else:
        subjects = base.subargs_to_subjects(args.subjects, dir_tree, sub_dir)

    if len(subjects) == 0:
        raise Exception("No subjects found.")

    return subjects


def get_raw_subjects(dir_tree, num=None, completed_subs=base.Subjects()):
    dirs = os.listdir(dir_tree.raw_dir)
    zipped_dirs = sorted([dir for dir in dirs if ".zip" in dir])
    unzipped_dirs = sorted(
        [dir for dir in dirs if len(dir) > 8 and "zip" not in dir])
    symbolic_links = sorted([dir for dir in dirs if len(dir) == 5])

    print(completed_subs)
    # gets latest zipped data that needs to be converted
    zips_to_run = []
    for zip in zipped_dirs:
        needs_zipping = True
        for unzip in unzipped_dirs:
            if zip.replace(".zip", "") in unzip:
                needs_zipping = False
                break
        if needs_zipping:
            zips_to_run.append(zip)

    if symbolic_links:
        subject = max(map(int, symbolic_links)) + 1
    else:
        subject = 10001

    # get subjects that have been unzipped and a symbolic link created, but are
    # not yet complete
    subjects = [
        sub for sub in symbolic_links if sub not in completed_subs.to_subargs_list()
    ]

    for zip in zips_to_run:
        print(f"Uzipping {zip}")
        with zipfile.ZipFile(dir_tree.raw_dir + zip, mode="r") as zip_ref:
            zip_ref.extractall(path=dir_tree.raw_dir)
        unzipped_dir = max(glob.iglob(
            f"{dir_tree.raw_dir}*"), key=os.path.getctime)
        final_unzipped_dir = (
            f'{dir_tree.raw_dir}{zip.replace(".zip", "___")}{str(subject)}'
        )
        os.rename(unzipped_dir, final_unzipped_dir)
        print(f"Unzipped {zip} to {final_unzipped_dir}")

        symbolic_link_dir = dir_tree.raw_dir + str(subject)
        print(
            f"Created symbolic link {symbolic_link_dir} for {final_unzipped_dir}")
        os.symlink(final_unzipped_dir, symbolic_link_dir)
        subjects.append(str(subject))
        subject += 1

    if num:
        subjects = subjects[:num]
    return base.subargs_to_subjects(subjects, dir_tree)


def run_stack(process, args, dir_tree, completed_subs):
    num_stacks = int(args.stack[0])
    stack_array = np.zeros(shape=(num_stacks))

    if args.stack[1] == "split":
        total_subjects = len(get_subjects(
            process, args, dir_tree, completed_subs))
        subjects_per_stack = math.floor(total_subjects / num_stacks)
        stack_array = np.full(num_stacks, subjects_per_stack)
        for i in range(total_subjects % num_stacks):
            stack_array[i] += 1
    else:
        stack_array = np.full(num_stacks, int(args.stack[1]))

    for numsub in np.nditer(stack_array):
        subjects = get_subjects(process, args, dir_tree,
                                completed_subs, numsub=numsub)
        completed_subs.extend(subjects)
        args.hold_jid = run_process(process, args, dir_tree, subjects)

    print("Finished stack successfully.")


def run_process(process, args, dir_tree, subjects):
    """
    Create final bashfile for process. Runs bashfile on host. If on thalamege,
    will wait for process to complete. All subjects will run asynchronously.
    Returns: (str) Job ID when submitted on argon.
    """
    # create base bashfile with options for hpc computing
    if process == s.FD_STATS:
        motion.print_FD_stats(dir_tree, subjects, threshold=args.threshold)
        exit()
    elif process == s.REGRESSORS:
        # add default columns, avoiding duplicates
        if not args.no_default:
            for def_column in s.DEFAULT_COLUMNS:
                if def_column not in args.columns:
                    args.columns.append(def_column)
                else:
                    print(
                        f"You entered the column {def_column} that already "
                        "exists in the default columns. This is unnecessary."
                    )
        print(f"Extracting columns {args.columns} from regressor files")

        for subject in subjects:
            regressors.parse_regressors(
                subject, args.columns, args.threshold, args.regressors_wc
            )
        exit()

    base_bashfile = bashwriter.Bashfile(
        f"{dir_tree.dataset_name}_{process}",
        subjects,
        args,
        f"{args.scripts_dir}jobs/{dir_tree.dataset_name}/",
        f"{dir_tree.dataset_dir}{process}/",
    )

    qsub_filepath = prep_bashfile(
        process, args, dir_tree, subjects, base_bashfile)

    return submit_bashfile(qsub_filepath, args, subjects)


def prep_bashfile(process, args, dir_tree, subjects, base_bashfile):
    """Replaces options in base bashfile to create new"""
    options = None
    bashfile_path = ""

    # heudiconv
    if process == s.HEUDICONV:
        if not args.is_thalamege:
            raise Exception("Must run on thalamege.")
        bashfile_path = s.HEUDICONV_BASHFILE

    # mriqc
    if process == s.MRIQC:
        if args.group:
            bashfile_path = s.MRIQC_GROUP_BASHFILE
            subjects = []
        else:
            bashfile_path = s.MRIQC_BASHFILE
        options = args.mriqc_opt

    # fmriprep
    elif process == s.FMRIPREP:
        bashfile_path = s.FMRIPREP_BASHFILE
        options = args.fmriprep_opt

    # 3dDeconvolve
    elif process == s.DECONVOLVE:

        # add default columns, avoiding duplicates
        if not args.no_default:
            for def_column in s.DEFAULT_COLUMNS:
                if def_column not in args.columns:
                    args.columns.append(def_column)
                else:
                    print(
                        f"You entered the column {def_column} that already "
                        "exists in the default columns. This is unnecessary."
                    )
        print(f"Extracting columns {args.columns} from regressor files")

        if not args.timing_file_dir:
            args.timing_file_dir = dir_tree.bids_dir

        for subject in subjects:
            print(f"Prepping 3dDeconvolve on subject {subject.name}")

            regressors.parse_regressors(
                subject, args.columns, args.threshold, args.regressors_wc
            )

            run_files = base.get_ses_files(
                subject, args.timing_file_dir, args.run_timing_wc)
            stimfile_creator = stimfiles.StimfileCreator(
                run_files,
                subject,
                args.stimulus_col,
                args.timing_col,
            )
            stimfile_creator.create_stimfiles()

        qsub_3d.write_qsub(
            base_bashfile, dir_tree, stimfile_creator.stimfiles, args.use_stimfiles, args.bold_wc
        )
        exit()

    # 3dMEMA
    elif process == s.MEMA:
        bashfile_path = s.MEMA_BASHFILE
        qsub_filepath = setup_mema(dir_tree, args, subjects, base_bashfile)
        return qsub_filepath

    qsub_filepath = qsub_fmriprep.write_qsub(
        args.scripts_dir + bashfile_path, base_bashfile, dir_tree, args, options
    )

    return qsub_filepath


def submit_bashfile(qsub_filepath, args, subjects):
    print('hello')
    if args.is_qsub and not args.is_thalamege:
        if len(subjects) == 1:
            completed_proc = subprocess.run(
                s.QSUB + qsub_filepath, shell=True, capture_output=True, text=True
            )
        else:
            completed_proc = subprocess.run(
                s.QSUB + qsub_filepath + s.ARRAY_QSUB,
                shell=True,
                capture_output=True,
                text=True,
            )

        job_id = int(completed_proc.stdout)
        if completed_proc.returncode != 0:
            raise Exception("Job failed to submit")

        print(
            f"Job {job_id} with {len(subjects)} task/s successfully submitted "
            "on Argon!"
        )
        return job_id

    elif args.is_thalamege:
        print(
            f"Submitting bashfile {qsub_filepath} on thalamege. Program will "
            "wait for process to complete.\n"
        )
        completed_proc = subprocess.run(
            s.BASH + qsub_filepath, shell=True, stdout=sys.stdout, stderr=sys.stderr
        )
        print("Success! Script finished running on thalamege.")


def setup_mema(dir_tree, args, subjects, base_bashfile):
    coefficient = np.arange(args.starting_index, args.ending_index, 3)
    tstat = np.arange(args.starting_index + 1, args.ending_index + 1, 3)

    # 3dmema need brackets around bucket index
    coefficients = [f"[{str(x)}]" for x in coefficient]
    tstats = [f"[{str(x)}]" for x in tstat]
    print(coefficient)
    print(tstats)

    # get conditions from stimulus config file
    df = pd.read_csv(dir_tree.deconvolve_dir + s.STIM_CONFIG)
    conditions = df[s.STIM_LABEL].tolist()
    print(conditions)
    print(len(conditions))

    subject_lines = []
    for subject in subjects:
        subject_lines.append(
            f"{subject.name} "
            f'{subject.deconvolve_dir}{s.BUCKET_FILE_BRIK}{"${coef[$c]}"} '
            f'{subject.deconvolve_dir}{s.BUCKET_FILE_BRIK}{"${tstat[$c]}"} \\'
        )

    with open(args.scripts_dir + s.MEMA_BASHFILE) as file:
        bashfile = file.read()
    bashfile = bashfile.replace(s.DATASET_KEY, dir_tree.dataset_dir)
    bashfile = bashfile.replace(s.SLOTS_KEY, str(base_bashfile.slots))
    bashfile = bashfile.replace(s.SGE_KEY, "\n".join(base_bashfile.sge_lines))
    bashfile = bashfile.replace(
        s.BASE_SCRIPT_KEY, "\n".join(base_bashfile.script))
    bashfile = bashfile.replace(s.COEF_KEY, " ".join(coefficients))
    bashfile = bashfile.replace(s.TSTAT_KEY, " ".join(tstats))
    bashfile = bashfile.replace(s.COND_KEY, " ".join(conditions))
    bashfile = bashfile.replace(s.MEMA_SUBJECTS_KEY, "\n".join(subject_lines))
    bashfile = bashfile.replace(s.EFILE_KEY, base_bashfile.efile)

    return bashwriter.write_file(
        bashfile, base_bashfile.output_dir, base_bashfile.job_name
    )


def parse_subcommands(args, subparsers):
    args_before_subcommands = []
    subcommands = []
    current_subcommand = []

    subcommand_index = 0
    for index, arg in enumerate(args[1:]):
        if arg not in subparsers:
            args_before_subcommands.append(arg)
        else:
            subcommand_index = index + 1
            break

    for arg in args[subcommand_index:]:
        if arg in subparsers:
            if current_subcommand:
                current_subcommand = args_before_subcommands + current_subcommand
                subcommands.append(current_subcommand)
            current_subcommand = []
            current_subcommand.append(arg)
        else:
            current_subcommand.append(arg)

    current_subcommand = args_before_subcommands + current_subcommand
    subcommands.append(current_subcommand)
    return subcommands


def main():
    # Parse command line arguments and separate subcommands
    parser = init_argparse()
    subcommands = parse_subcommands(sys.argv, s.DEFAULT_WORKFLOW)

    # loop through each subcommand and perform relevant functions
    for subcommand in subcommands:
        args = parser.parse_args(subcommand)

        # find which host location and set paths
        HOSTNAME = socket.gethostname()
        if s.THALAMEGE_HOST in HOSTNAME:
            args.is_thalamege = True
            args.scripts_dir = s.MEGE_SCRIPTS_DIR
            if not args.work_dir:
                args.work_dir = args.dataset_dir + paths.WORK_DIR
                if not os.path.exists(args.work_dir):
                    os.makedirs(args.work_dir)
        elif s.ARGON_HOST in HOSTNAME:
            args.is_thalamege = False
            args.scripts_dir = s.ARGON_SCRIPTS_DIR
            if not args.work_dir:
                args.work_dir = (
                    f"{s.LOCALSCRATCH}{getpass.getuser()}/" "${JOB_ID}_${SGE_TASK_ID}/"
                )
        else:
            raise Exception(
                "Unrecognized server host. Must be Thalamege or Argon.")

        # Create directory tree, contains basely used dataset paths
        dir_tree = base.DirectoryTree(
            args.dataset_dir,
            bids_dir=args.bids_dir,
            work_dir=args.work_dir,
            sessions=args.sessions if hasattr(args, "sessions") else None,
        )

        # set and create process directory and relevant sub directories
        # HEUDICONV process dir is the raw dir
        # FD_stats process dir is analysis dir
        process = args.subcommand
        if process == s.HEUDICONV:
            dir_tree.process_dir = dir_tree.raw_dir
        elif process == s.FD_STATS:
            dir_tree.process_dir = dir_tree.analysis_dir
        elif process == s.REGRESSORS:
            dir_tree.process_dir = dir_tree.fmriprep_dir
        else:
            dir_tree.process_dir = f"{dir_tree.dataset_dir}{process}/"

        log_dir = dir_tree.process_dir + paths.LOGS_DIR
        if not os.path.isdir(log_dir):
            os.makedirs(log_dir)
        if not os.path.isdir(dir_tree.bids_dir):
            os.makedirs(dir_tree.bids_dir)

        # get completed subjects
        completed_subs = base.Subjects()
        if os.path.exists(log_dir + s.COMPLETED_SUBS_FILE):
            completed_subs = base.read_file_subargs(
                log_dir + s.COMPLETED_SUBS_FILE, dir_tree
            )

        if not args.is_thalamege and args.stack:
            run_stack(process, args, dir_tree, completed_subs)
            exit()

        subjects = get_subjects(process, args, dir_tree,
                                completed_subs, args.numsub)
        run_process(process, args, dir_tree, subjects)


main()
