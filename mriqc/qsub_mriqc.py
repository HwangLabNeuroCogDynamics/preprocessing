import settings as s
from lib import bashwriter


def write_qsub(base_filepath, bashfile_options, dir_tree, mriqc_opt):
    """Replaces keys in base bashfile to create new bash submission file for
     given job. Compatible with both mriqc and fmriprep bashfiles."""
    with open(base_filepath) as file:
        bashfile = file.read()
        bashfile = bashfile.replace(s.DATASET_KEY, dir_tree.dataset_dir)
        bashfile = bashfile.replace(s.SLOTS_KEY, str(bashfile_options.slots))
        bashfile = bashfile.replace(s.BIDS_KEY, dir_tree.bids_dir)
        bashfile = bashfile.replace(s.WORK_KEY, dir_tree.work_dir)
        bashfile = bashfile.replace(s.SUBS_KEY, bashfile_options.sub_args)
        bashfile = bashfile.replace(
            s.SGE_KEY, "\n".join(bashfile_options.sge_lines))
        bashfile = bashfile.replace(
            s.BASE_SCRIPT_KEY, "\n".join(bashfile_options.script))
        bashfile = bashfile.replace(s.EFILE_KEY, bashfile_options.efile)
        if mriqc_opt:
            bashfile = bashfile.replace(s.OPTIONS_KEY, mriqc_opt)
        else:
            bashfile = bashfile.replace(s.OPTIONS_KEY, '')

        return bashwriter.write_file(bashfile, bashfile_options.output_dir,
                                     bashfile_options.job_name)
