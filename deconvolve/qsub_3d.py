import pandas as pd
import settings as s
from lib import bashwriter
import os
from thalpy import base
from thalpy.constants import wildcards, paths


def convert_stim_config(df, stim_times, gltsym, iresp):
    for index, row in df.iterrows():
        stim_times.append(
            (
                f"-stim_times {index + 1} {row['Stimulus File']} {row['Model']} "
                f"-stim_label {index + 1} {row['Stim Label']} \\"
            )
        )
        gltsym.append(
            f'-gltsym "SYM: +1*{row["Stim Label"]}" -glt_label {index + 1} {row["Stim Label"]} \\'
        )
        iresp.append(
            f'-iresp {index + 1} {row["Stim Label"]}_FIR_MIN.nii.gz \\')

        group_gltsym = "-gltsym SYM:"
        grouped_stimuli = df.groupby("Group")
        for name, group in grouped_stimuli:
            group_gltsym = '-gltsym "SYM:'
            for index, row in group.iterrows():
                group_gltsym += f' +1*{row["Stim Label"]}'
            group_gltsym += f'" -glt_label {len(gltsym) + 1} {name} \\'
            gltsym.append(group_gltsym)


def convert_stimfiles(stimfiles, stim_times, gltsym, iresp):
    for index, stimfile in enumerate(stimfiles):
        stim_times.append(
            f"-stim_times {index + 1} {stimfile.file}"
            f"-stim_label {index + 1} {stimfile.name} \\"
        )
        gltsym.append(
            f'-gltsym "SYM: +1*{stimfile.name}" -glt_label {index + 1} {stimfile.name} \\'
        )
        iresp.append(f"-iresp {index + 1} {stimfile.name}_FIR_MIN.nii.gz \\")


def load_stimtimes(deconvolve_dir, stimfiles, use_stimfiles):
    stim_times, gltsym, iresp = ([] for i in range(3))

    stim_config_path = deconvolve_dir + s.STIM_CONFIG
    if os.path.exists(stim_config_path) and not use_stimfiles:
        df = pd.read_csv(stim_config_path)
        convert_stim_config(df, stim_times, gltsym, iresp)
    else:
        convert_stimfiles(stimfiles, stim_times, gltsym, iresp)

    stim_times.insert(0, f"-num_stimts {len(stim_times)} \\")
    gltsym.insert(0, f"-num_glt {len(gltsym)} \\")

    return stim_times + iresp + gltsym


def write_qsub(base_bashfile, dir_tree, stimfiles, use_stimfiles, bold_wc):
    bashfile = list()
    stimlines = load_stimtimes(
        dir_tree.deconvolve_dir, stimfiles, use_stimfiles)

    bashfile.extend(base_bashfile.sge_lines)
    bashfile.extend(base_bashfile.script)

    bashfile.append(f'echo "Starting {s.DECONVOLVE} on $subject"')
    bashfile.append(f"cd {dir_tree.deconvolve_dir}sub-$subject/ \n")
    # create mask
    bashfile.append(f"{s.SING_RUNCLEAN} {s.AFNI_SING_PATH} \\")
    # mask_files = [
    #     base.get_ses_files(sub, sub.fmriprep_dir, "*mask.nii.gz") for sub in subjects
    # ]
    # data_files = [
    #     base.get_ses_files(sub, sub.fmriprep_dir, wildcards.BOLD_WC) for sub in subjects
    # ]

    if dir_tree.sessions:
        bashfile.append(
            (
                f"3dmask_tool -input $(find {dir_tree.fmriprep_dir} -regex "
                f'"{dir_tree.fmriprep_dir}sub-$subject/\({"%".join(dir_tree.sessions)}\).*mask\.nii\.gz") \n'.replace(
                    "%", "\|"
                )
            )
        )
    else:
        bashfile.append(
            (
                f"3dmask_tool -input $(find {dir_tree.fmriprep_dir} -regex "
                f'"{dir_tree.fmriprep_dir}sub-$subject.*mask\.nii\.gz") \n'.replace(
                    "%", "\|"
                )
            )
        )

    # run 3dDeconvolve
    bashfile.append(f"{s.SING_RUNCLEAN} {s.AFNI_SING_PATH} \\")
    if dir_tree.sessions:
        bashfile.append(
            f"{s.DECONVOLVE} -input $(find {dir_tree.fmriprep_dir} -regex "
            f'"{dir_tree.fmriprep_dir}sub-$subject/\({"%".join(dir_tree.sessions)}\).*{bold_wc}" -print0 | sort -z | xargs -r0) \\'.replace(
                "%", "\|"
            )
        )
    else:
        bashfile.append(
            f"{s.DECONVOLVE} -input $(find {dir_tree.fmriprep_dir} -regex "
            f'"{dir_tree.fmriprep_dir}sub-$subject/.*{bold_wc}" -print0 | sort -z | xargs -r0) \\'.replace(
                "%", "\|"
            )
        )

    bashfile.append(f"-mask {s.MASK_FILE} \\")
    bashfile.append("-polort A \\")
    bashfile.append(f"-censor {paths.CENSOR_FILE} \\")
    bashfile.append(f"-ortvec {paths.REGRESSOR_FILE} nuisance \\")
    bashfile.append("-local_times \\")
    bashfile.extend(stimlines)

    bashfile.append("-rout \\")
    bashfile.append("-tout \\")
    bashfile.append(f"-bucket {s.BUCKET_FILE} \\")
    bashfile.append(f"-errts {s.ERRTS_FILE} \\")
    bashfile.append("-noFDR \\")
    bashfile.append("-nocout \\")
    bashfile.append(f"-jobs {base_bashfile.slots} \\")
    bashfile.append("-ok_1D_text")
    bashfile = "\n".join(bashfile)
    return bashwriter.write_file(
        bashfile, base_bashfile.output_dir, base_bashfile.job_name
    )
