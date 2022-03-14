from thalpy import base
from thalpy.constants import wildcards, paths
import pandas as pd
import math


def print_FD_stats(dir_tree, subjects, threshold=0.2):
    run_output_df = pd.DataFrame(
        columns=["Subject", "Run", "Mean FD", f"% points over {threshold}"]
    )
    sub_output_df = pd.DataFrame(
        columns=["Subject", "Mean FD", f"% points over {threshold}"]
    )
    run_index = 0
    print(subjects)
    for subject_index, subject in enumerate(subjects):
        sub_files = base.get_ses_files(
            subject, subject.fmriprep_dir +
            paths.FUNC_DIR, f"*{wildcards.REGRESSOR_WC}"
        )
        sub_points_over = 0
        total_points = 0
        FD_total = 0
        for file in sub_files:
            # session = common.parse_ses_from_file(file)
            # dir = common.parse_dir_from_file(file)
            # run = common.parse_run_from_file(file)
            # task = common.parse_task(file)
            df = pd.read_csv(file, "\t")

            # get pct of points over threshold
            run_points_over = 0
            run_total_points = 0
            run_FD = 0
            for point in zip(df["framewise_displacement"]):
                if point[0] >= threshold:
                    run_points_over += 1
                elif math.isnan(point[0]):
                    continue
                run_total_points += 1
                run_FD += point[0]

            sub_points_over += run_points_over
            total_points += run_total_points
            FD_total += run_FD

            if run_total_points == 0:
                continue
            run_FD_mean = run_FD / run_total_points
            run_pct_points_over = (run_points_over / run_total_points) * 100

            run_output_df.loc[run_index] = [
                subject.name,
                file.split("/")[-1],
                run_FD_mean,
                run_pct_points_over,
            ]
            run_index += 1

        if total_points == 0:
            continue

        pct_points_over = (sub_points_over / total_points) * 100
        FD_mean = FD_total / total_points
        print(subject.name)
        print(FD_mean)
        print(pct_points_over)
        # add row onto output dataframe
        sub_output_df.loc[subject_index] = [
            subject.name, FD_mean, pct_points_over]

    run_output_df.to_csv(dir_tree.analysis_dir +
                         "FD_stats_runs.csv", index=False)
    sub_output_df.to_csv(dir_tree.analysis_dir +
                         "FD_stats_subject.csv", index=False)
