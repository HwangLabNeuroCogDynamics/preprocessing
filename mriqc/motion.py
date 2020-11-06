from lib import common
import pandas as pd
import settings as s
import sys


def print_FD_stats(dataset_dir, threshold=0.2):
    dir_tree = common.DirectoryInfo(dataset_dir)
    subjects = common.get_subjects(dir_tree)
    output_df = pd.DataFrame

    print(f'Subject\tSession\tRun\tMean FD\t% points over {threshold}')
    for index, subject in enumerate(subjects):
        files = common.get_ses_files(subject.sessions,
                                     f"{subject.fmriprep_dir}{s.SESSION}/{s.FUNC_DIR}*{s.REGRESSOR_WC}")
        print(files)

        for file in files:
            session = common.parse_ses_from_file(file)
            run = common.parse_run_from_file(file)
            df = pd.read_csv(file, sep="\t")

            points_over = 0
            for point in zip(df['framewise_displacement']):
                if point[0] >= threshold:
                    points_over += 1
            pct_points_over = (points_over / len(df.index)) * 100

            FD_mean = df['framewise_displacement'].mean()

            print(f'{session}\t{run}\t{FD_mean}\t{pct_points_over}')


if __name__ == '__main__':
    globals()[sys.argv[1]](sys.argv[2])
