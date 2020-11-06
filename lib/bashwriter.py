import os
import settings as s
import getpass


# Classes
class Bashfile:
    '''Class containing base options for creating bashfile.'''

    def __init__(self, job_name, subjects, args, output_dir, process_dir):
        self.job_name = job_name
        self.sge_lines = []
        self.script = []
        self.sub_args = subjects.to_subargs()
        self.total_tasks = len(subjects)
        self.slots = args.slots
        self.mem = args.mem
        self.no_resubmit = args.no_resubmit
        self.is_emailed = args.email
        self.hold_jid = args.hold_jid
        self.is_thalamege = args.is_thalamege
        self.output_dir = output_dir
        self.process_dir = process_dir

        work_dir_base = f'{s.LOCALSCRATCH}{getpass.getuser()}/'
        if self.total_tasks > 0:
            self.ofile = work_dir_base + '$JOB_NAME_$TASK_ID.o'
            self.efile = work_dir_base + '$JOB_NAME_$TASK_ID.e'
        else:
            self.ofile = work_dir_base + '$JOB_NAME.o'
            self.efile = work_dir_base + '$JOB_NAME.e'

        if args.queue:
            self.queue = args.queue
        elif self.total_tasks * self.slots <= 160:
            self.queue = s.DEFAULT_QUEUE
        else:
            self.queue = s.LARGE_QUEUE

        self.create_base()

    def create_base(self):
        # set sge options
        self.sge_lines.append(f"#$ -N {self.job_name}")
        self.sge_lines.append(f"#$ -q {self.queue}")
        self.sge_lines.append(f"#$ -pe smp {self.slots}")
        self.sge_lines.append(f"#$ -o {self.ofile}")
        self.sge_lines.append(f"#$ -e {self.efile}")

        if self.total_tasks > 1:
            self.sge_lines.append(f"#$ -t 1-{self.total_tasks}")
            if not self.no_resubmit:
                self.sge_lines.append("#$ -ckpt user")

        if self.mem:
            self.sge_lines.append(f'#$ -l {self.mem}')

        if self.hold_jid:
            self.sge_lines.append(f'#$ -hold_jid_ad {self.hold_jid}')

        if self.is_emailed:
            self.sge_lines.append("#$ -m e")
            self.sge_lines.append(f"#$ -M {getpass.getuser()}@uiowa.edu")

        self.sge_lines.append(f'export OMP_NUM_THREADS={self.slots}')

        # start script
        self.script.append("/bin/echo Running on compute node: `hostname`.")
        self.script.append("/bin/echo Job: $JOB_ID")
        if self.total_tasks > 1:
            self.script.append("/bin/echo Task: $SGE_TASK_ID")
        self.script.append("/bin/echo In directory: `pwd`")
        self.script.append("/bin/echo Starting on: `date`")
        self.script.append('\n')

        if self.is_thalamege:
            self.script.append(f'subjects=({self.sub_args})')
            self.script.append('echo subjects: ${subjects[@]}')
        elif self.total_tasks > 1:
            self.script.append(f'subjects=({self.sub_args})')
            self.script.append('echo subjects: ${subjects[@]}')
            self.script.append('echo total_subjects=${#subjects[@]}')
            self.script.append('subject="${subjects[$SGE_TASK_ID-1]}"')
        else:
            self.script.append(f'subject={self.sub_args[0]}')
            self.script.append('echo subject: $subject')


# Functions
def write_file(bashfile, output_dir, job_name):
    ''' '''
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    index = 1
    filepath = f'{output_dir}{job_name}.sh'
    while os.path.isfile(filepath):
        index += 1
        filepath = f'{output_dir}{job_name}_{index}.sh'

    with open(filepath, 'w') as file:
        file.write(bashfile)

    return filepath
