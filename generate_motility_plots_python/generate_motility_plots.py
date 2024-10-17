#!/usr/bin/python3

# This program automatically generates plots using the raw output of motility data from ImageJ TrackMate analysis.
# helpful for visualizing results before investing more time in the TrackMate analysis.
# 1 argument: directory of data files
# to use: execute "python3 generate_motility_plots.py <directory_with_data>"
# if using the program from within the same directory as the data files execute "python3 generate_motility_plots.py ."


# packages
import glob
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sb
import os
import argparse



# main program
def main():
    plot_motility('distance') # make plot
    plt.savefig('distance_plot.jpg', dpi=300, bbox_inches='tight') # save new figure
    plot_motility('velocity') # repeat with second motility metric
    plt.savefig('velocity_plot.jpg', dpi=300, bbox_inches='tight')
    print("plots generated.")



# get input arguement for directory with data files
parser = argparse.ArgumentParser(description="process input directory")
parser.add_argument('directory', type=str, help='the directory to use')
args = parser.parse_args()
directory = args.directory


# plot function
def plot_motility(data_type):
    """
    this function plots the well level comparisons for input motility data type for all corresponding data files that are present
    input: name of the data type to plot (eg 'distance' which will have corresponding data files)
    output: returns the single plot
    """
    # setup overall
    files = f'*{data_type}.csv'
    csv_files = glob.glob(os.path.join(directory, files))  # use all files with the corresponding data type
    plot_df = pd.DataFrame()   # empty df

    # loop target files and append to single df
    for file in csv_files:
        well = file[-15:-13]
        data_df = pd.read_csv(file)
        data_df['Metadata_Well'] = well
        plot_df = pd.concat([plot_df, data_df], ignore_index=True)

    col_to_plot = str(plot_df.columns[1])
    num_wells = plot_df["Metadata_Well"].nunique()

    # plot concatenated data
    sb.set(style="white")
    colors = sb.color_palette("Set2", num_wells)
    plt.figure(figsize=(6, 4))
    plot = sb.stripplot(x='Metadata_Well', y=col_to_plot, data=plot_df,
                        marker='o', edgecolor='black', palette=colors, hue="Metadata_Well", legend=False)
    plt.xlabel('Well')
    plt.ylabel(f'{col_to_plot}')
    plt.title(f'Motility: {data_type} per well')
    plot.tick_params(axis='x', labelrotation=45)  # Rotate x-axis labels for better readability
    # calc mean
    mean_values = plot_df.groupby("Metadata_Well")[col_to_plot].mean()
    # Add a horizontal line at the mean position
    x_positions = [plot.get_xticks()[i] for i, _ in enumerate(mean_values)]
    plot.bar(x=x_positions, height=mean_values, width=0.2, color='black', alpha=0.7, label='Mean')

    return plot


if __name__ == "__main__":
    main()

