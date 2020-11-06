import os
import argparse
import subprocess
from lib import bashwriter
import common
import basic_settings as bs
from deconvolve import prep_3d, qsub_3d
from fmriprep import qsub_fmriprep
import settings as s
import getpass
import numpy as np
import math
import socket
import zipfile
import sys
import glob as glob


def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run pre-processing on whole dataset or selected subjects",
        usage="[SUBJECT_DIRECTORY] [OPTIONS] [SUBCOMMANDS] ... ",
        add_help=False)

    # Required arguments
    required = parser.add_argument_group('Required Arguments')
    required.add_argument('dataset_dir',
                          help="Base directory of dataset.")

    # Optional arguments
    general = parser.add_argument_group('General Optional Arguments')
    general.add_argument("-h", "--help",
                         action="help",
                         help="show this help message and exit")
    general.add_argument('--bids_dir',
                         help='Path for bids directory if not located in '
                         'dataset directory.')
    general.add_argument('-n', '--numsub',
                         type=int,
                         help="""The number of subjects being analyzed. If none
                                    listed, default will be whole dataset""")
    general.add_argument('--rerun',
                         action='store_true',
                         default=False,
                         help="Rerun failed subjects (non-memory issues)")
    general.add_argument('--rerun_mem',
                         action='store_true',
                         default=False,
                         help="Rerun subjects that failed due to memory constraints")
    general.add_argument('-s', '--subjects',
                         nargs='*',
                         help="""The subjects being analyzed. Do not include
                         sub- prefix. If subjects are not included,
                         pre-processing will be run on whole dataset by default
                         or on number of subjects given via the --numsub flag""")
    general.add_argument('--work_dir',
                         help="""The working dir for programs. Default for argon
                         is user dir in localscratch. Default for thalamege is
                         work directory in dataset directory.""")

    argon = parser.add_argument_group('Argon HPC Optional Arguments')
    argon.add_argument('--email',
                       action='store_true',
                       help="Receive email notifications from HPC")

    argon.add_argument('--hold_jid',
                       help="""Jobs will be placed on hold until specified job
                             completes. [JOB_ID]""")
    argon.add_argument('--no_qsub',
                       default=True,
                       action='store_false',
                       dest='is_qsub',
                       help="Does not submit generated bash scripts to Argon")
    argon.add_argument('--no_resubmit',
                       action='store_true',
                       default=False,
                       help="""Enable to not resubmit tasks after migration.
                            Default is to resubmit.""")

    argon.add_argument('--mem',
                       help="Set memory for HPC")
    argon.add_argument('-q', '--queue',
                       help="Set queue for HPC")

    argon.add_argument('--slots',
                       type=int,
                       help="""Set number of slots/threads per subject. Default
                            is 16.""",
                       default=16)
    argon.add_argument('--stack',
                       nargs=2,
                       help="""Queue jobs in dependent stacks. When all jobs
                            complete, next will start. Two required integer
                            arguments [# of stacks][# of jobs per stack]. Use
                            'split' in second argument to split remaining jobs
                            evenly amongst number of stacks.""")

    subparsers = parser.add_subparsers(title='Subcommands', required=True,
                                       dest='subcommand')

    heudiconv_parser = subparsers.add_parser('heudiconv',
                                             usage='[SCRIPT_PATH][OPTIONS]',
                                             help='''Convert raw data files to
                                                 BIDS format. Conversion script
                                                 filepath is required.''')
    heudiconv_parser.add_argument('script_path',
                                  help='''Filename of script. Script must be
                                      located in following directory:
                                      /data/backed_up/shared/bin/heudiconv/heuristics/''')

    mriqc_parser = subparsers.add_parser('mriqc',
                                         usage='[OPTIONS]',
                                         help='''Run mriqc on dataset to analyze
                                             quality of data.''')
    mriqc_parser.add_argument('--group',
                              action='store_true',
                              help="""Run group analysis for mriqc instead of default
                                participant level""")
    mriqc_parser.add_argument('--mriqc_opt',
                              help='Options to add to mriqc. Write between \'\' as'
                              ' shown: \'--[OPTION1] --[OPTION2] ...\'')

    fmriprep_parser = subparsers.add_parser('fmriprep',
                                            usage='[OPTIONS]',
                                            help='''Preprocess data with
                                                fmriprep pipeline.''')
    fmriprep_parser.add_argument('--fmriprep_opt',
                                 help="""Options to add to fmriprep. Write between \'\'
                                     and replace - with * as shown: \'**[OPTION1] arg1 **[OPTION2] ...\'""")

    return parser


def get_subjects(process, args, dir_tree, completed_subs, numsub=None):
    '''
    Based on args specs, gets specified type of subjects. If numbsub is None,
    all subjects will be returned. Otherwise, will return numsub subjects.
    Returns: [Subjects]  list of subjects in subject object form
    '''
    subjects = common.Subjects()
    # get subjects to run and instantiate list of subject objects
    if args.rerun:
        subjects = common.read_file_subargs(
            dir_tree.process_dir + s.LOGS_DIR + s.FAILED_SUB_FILE,
            dir_tree, num=numsub)

    elif args.rerun_mem:
        subjects = common.read_file_subargs(
            dir_tree.process_dir + s.LOGS_DIR + s.FAILED_SUB_MEM_FILE,
            dir_tree, num=numsub)
        args.slots = 20
        if not args.mem:
            args.mem = 'mem_256G=true'

    elif process == s.HEUDICONV:
        subjects = get_raw_subjects(dir_tree, completed_subs=completed_subs,
                                    num=numsub)

    elif args.subjects is None:
        subjects = common.get_subjects(dir_tree, completed_subs=completed_subs,
                                       num=numsub)

    else:
        subjects = common.subargs_to_subjects(args.subjects, dir_tree)

    return subjects


def get_raw_subjects(dir_tree, num=None, completed_subs=common.Subjects()):
    dirs = os.listdir(dir_tree.raw_dir)
    zipped_dirs = sorted([dir for dir in dirs if '.zip' in dir])
    unzipped_dirs = sorted([dir for dir in dirs
                            if len(dir) > 8 and 'zip' not in dir])
    symbolic_links = sorted([dir for dir in dirs if len(dir) == 5])

    print(completed_subs)
    # gets latest zipped data that needs to be converted
    zips_to_run = []
    for zip in zipped_dirs:
        needs_zipping = True
        for unzip in unzipped_dirs:
            if zip.replace('.zip', '') in unzip:
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
    subjects = [sub for sub in symbolic_links
                if sub not in completed_subs.to_subargs_list()]

    for zip in zips_to_run:
        print(f'Uzipping {zip}')
        with zipfile.ZipFile(dir_tree.raw_dir + zip, mode='r') as zip_ref:
            zip_ref.extractall(path=dir_tree.raw_dir)
        unzipped_dir = max(glob.iglob(
            f'{dir_tree.raw_dir}*'), key=os.path.getctime)
        final_unzipped_dir = f'{dir_tree.raw_dir}{zip.replace(".zip", "___")}{str(subject)}'
        os.rename(unzipped_dir, final_unzipped_dir)
        print(f'Unzipped {zip} to {final_unzipped_dir}')

        symbolic_link_dir = dir_tree.raw_dir + str(subject)
        print(
            f'Created symbolic link {symbolic_link_dir} for {final_unzipped_dir}')
        os.symlink(final_unzipped_dir, symbolic_link_dir)
        subjects.append(str(subject))
        subject += 1

    if num:
        subjects = subjects[:num]
    return common.subargs_to_subjects(subjects, dir_tree)


def run_process(process, args, dir_tree, subjects):
    '''
    Create final bashfile for process. Runs bashfile on host. If on thalamege,
    will wait for process to complete. All subjects will run asynchronously.
    Returns: (str) Job ID when submitted on argon.
    '''
    # create base bashfile with options for hpc computing
    base_bashfile = bashwriter.Bashfile(f'{dir_tree.dataset_name}_{process}',
                                        subjects, args,
                                        f'{args.scripts_dir}jobs/{dir_tree.dataset_name}/',
                                        f'{dir_tree.dataset_dir}{process}/')

    qsub_filepath = prep_bashfile(process, args, dir_tree,
                                  subjects, base_bashfile)

    return submit_bashfile(qsub_filepath, args, subjects)


def prep_bashfile(process, args, dir_tree, subjects, base_bashfile):
    '''Replaces options in base bashfile to create new'''
    options = None

    # heudiconv
    if process == s.HEUDICONV:
        if not args.is_thalamege:
            raise Exception('Must run on thalamege.')
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

        if not args.nodef:
            args.col.extend(s.DEFAULT_COLUMNS)
            print(f'Columns to parse: {args.col}')

        if not args.skip_decprep:
            for subject in subjects:
                print(f'Prepping 3dDeconvolve on subject {subject.name}')
                if not os.path.isdir(subject.deconvolve_dir):
                    os.mkdir(subject.deconvolve_dir)

                prep_3d.parse_regressors(subject, args.col)
                prep_3d.create_stimfiles(subject)

    qsub_filepath = qsub_fmriprep.write_qsub(args.scripts_dir + bashfile_path,
                                             base_bashfile, dir_tree, args,
                                             options)

    return qsub_filepath


def submit_bashfile(qsub_filepath, args, subjects):
    if args.is_qsub and not args.is_thalamege:
        if len(subjects) == 1:
            completed_proc = subprocess.run(s.QSUB + qsub_filepath, shell=True,
                                            capture_output=True, text=True)
        else:
            completed_proc = subprocess.run(s.QSUB + qsub_filepath + s.ARRAY_QSUB,
                                            shell=True, capture_output=True,
                                            text=True)

        job_id = int(completed_proc.stdout)
        if completed_proc.returncode != 0:
            raise Exception('Job failed to submit')

        print(
            f'Job {job_id} with {len(subjects)} task/s successfully submitted '
            'on Argon!')
        return job_id

    elif args.is_thalamege:
        print(
            f'Submitting bashfile {qsub_filepath} on thalamege. Program will '
            'wait for process to complete.\n')
        completed_proc = subprocess.run(s.BASH + qsub_filepath, shell=True,
                                        stdout=sys.stdout, stderr=sys.stderr)
        print('Success! Script finished running on thalamege.')


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
    # Parse command line arguments
    parser = init_argparse()
    commands = parse_subcommands(sys.argv, [s.HEUDICONV, s.MRIQC, s.FMRIPREP])

    for command in commands:
        args = parser.parse_args(command)

        # set host settings
        HOSTNAME = socket.gethostname()
        if s.THALAMEGE_HOST in HOSTNAME:
            args.is_thalamege = True
            args.scripts_dir = s.MEGE_SCRIPTS_DIR
            if not args.work_dir:
                args.work_dir = args.dataset_dir + bs.WORK_DIR
                if not os.path.exists(args.work_dir):
                    os.makedirs(args.work_dir)
        elif s.ARGON_HOST in HOSTNAME:
            args.is_thalamege = False
            args.scripts_dir = s.ARGON_SCRIPTS_DIR
            if not args.work_dir:
                args.work_dir = (f'{s.LOCALSCRATCH}{getpass.getuser()}/'
                                 '${JOB_ID}_${SGE_TASK_ID}/')
        else:
            raise Exception(
                'Unrecognized server host. Must be Thalamege or Argon.')

        # Create directory tree
        dir_tree = common.DirectoryTree(args.dataset_dir, args.bids_dir,
                                        args.work_dir)

        # set and create process directory and relevant sub directories
        process = args.subcommand
        dir_tree.process_dir = f'{dir_tree.dataset_dir}{process}/'
        if process == s.HEUDICONV:
            log_dir = dir_tree.raw_dir + bs.LOGS_DIR
        else:
            log_dir = dir_tree.process_dir + bs.LOGS_DIR
        if not os.path.isdir(log_dir):
            os.makedirs(log_dir)
        if not os.path.isdir(dir_tree.bids_dir):
            os.makedirs(dir_tree.bids_dir)

        # get completed subjects
        completed_subs = common.Subjects()
        if(os.path.exists(log_dir + s.COMPLETED_SUBS_FILE)):
            completed_subs = common.read_file_subargs(
                log_dir + s.COMPLETED_SUBS_FILE, dir_tree)

        # stacked
        if args.stack:
            num_stacks = int(args.stack[0])
            stack_array = np.zeros(shape=(num_stacks))

            if args.stack[1] == 'split':
                total_subjects = len(get_subjects(process, args, dir_tree,
                                                  completed_subs))
                subjects_per_stack = math.floor(
                    total_subjects / num_stacks)
                stack_array = np.full(num_stacks, subjects_per_stack)
                for i in range(total_subjects % num_stacks):
                    stack_array[i] += 1

            else:
                stack_array = np.full(num_stacks, int(args.stack[1]))

            for numsub in np.nditer(stack_array):
                subjects = get_subjects(process, args, dir_tree, completed_subs,
                                        numsub=numsub)
                completed_subs.extend(subjects)
                args.hold_jid = run_process(
                    process, args, dir_tree, subjects)

            print('Finished stack successfully.')
            exit()

        subjects = get_subjects(process, args, dir_tree,
                                completed_subs, args.numsub)
        run_process(process, args, dir_tree, subjects)


main()
