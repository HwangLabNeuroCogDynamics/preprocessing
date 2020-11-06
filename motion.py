from lib import common
import pandas as pd
import settings as s
import sys


def print_FD_stats(dataset_dir, bids_dir=None, threshold=0.2):
    dir_tree = common.DirectoryInfo(dataset_dir, bids_dir=bids_dir)
    subjects = common.get_subjects(dir_tree)
    output_df = pd.DataFrame(columns=['Subject', 'Session', 'Run',
                                      'Mean FD', f'% points over {threshold}'])
    files = list()

    for index, subject in enumerate(subjects):
        files.extend(common.get_ses_files(subject.sessions,
                                          f"{subject.fmriprep_dir}{s.SESSION}"
                                          f"/{s.FUNC_DIR}*{s.REGRESSOR_WC}"))

    for index, file in enumerate(files):
        print(file)
        subject = common.parse_sub_from_file(file)
        session = common.parse_ses_from_file(file)
        run = common.parse_run_from_file(file)
        df = pd.read_csv(file, "\t")

        # get pct of points over threshold
        points_over = 0
        for point in zip(df['framewise_displacement']):
            if point[0] >= threshold:
                points_over += 1
        pct_points_over = (points_over / len(df.index)) * 100

        # get FD mean
        FD_mean = df['framewise_displacement'].mean()

        # add row onto output dataframe
        output_df.loc[index] = [f'{subject}', f'{session}',
                                f'{run}', f'{FD_mean}', f'{pct_points_over}']
        print(len(output_df.index))

    output_df.to_csv('FD_stats.csv', index=False)


if __name__ == '__main__':
    globals()[sys.argv[1]](sys.argv[2])
