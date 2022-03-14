import settings as s
from lib import bashwriter


def write_qsub(base_filepath, bashfile_options, dir_tree, args, func_opt=None):
    """Replaces keys in base bashfile to create new bash submission file for
     given job. Compatible with heudiconv, mriqc, and fmriprep bashfiles."""
    with open(base_filepath) as file:
        bashfile = file.read()
    bashfile = bashfile.replace(s.DATASET_NAME_KEY, dir_tree.dataset_name)
    bashfile = bashfile.replace(s.DATASET_KEY, dir_tree.dataset_dir)
    bashfile = bashfile.replace(s.MRIQC_KEY, dir_tree.mriqc_dir)
    bashfile = bashfile.replace(s.SLOTS_KEY, str(bashfile_options.slots))
    bashfile = bashfile.replace(s.BIDS_KEY, dir_tree.bids_dir)
    bashfile = bashfile.replace(s.WORK_KEY, dir_tree.work_dir)
    if args.subcommand == s.HEUDICONV:
        bashfile = bashfile.replace(
            s.CONVERSION_SCRIPT_KEY, args.script_path)
        bashfile = bashfile.replace(
            s.POST_CONV_SCRIPT_KEY, args.post_conv_script)
    bashfile = bashfile.replace(
        s.SGE_KEY, "\n".join(bashfile_options.sge_lines))
    bashfile = bashfile.replace(
        s.BASE_SCRIPT_KEY, "\n".join(bashfile_options.script))
    bashfile = bashfile.replace(s.EFILE_KEY, bashfile_options.efile)
    if func_opt:
        bashfile = bashfile.replace(s.OPTIONS_KEY, func_opt)
    else:
        bashfile = bashfile.replace(s.OPTIONS_KEY, '')

        return bashwriter.write_file(bashfile, bashfile_options.output_dir,
                                     bashfile_options.job_name)
