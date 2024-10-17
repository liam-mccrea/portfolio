#!/usr/bin/env python3

# this program takes individual image field level ImageJ Trackmate motility data outputs and combines them to a single results file for the experiment.
# 1) set variables
# 2) execute "python3 Concatenate_motility_results.py" 



# packages
import os
import pandas as pd


# set variables (break down required metadata)
directory = '/Desktop/'
experiment = 'Motility_Analysis/'
plates = ['plate1', 'plate2']
intermediate = 'chemotaxis_migration_tool/output/'
sort_by = ['Condition', 'Well', 'Track Number']



#################### program start ##################

# main function
def main():
    master_df = concat_results()
    master_df_labeled = add_treatment_info(master_df)
    export_concat_file(master_df_labeled)


# concatenate individual results files to a single file
def concat_results():
    df_list = []
    complete_dist_df = pd.DataFrame() # initialize intermediate df's
    complete_velo_df = pd.DataFrame()
    for plate in plates:  # have to do plate by plate so that results aren't overwritten (need unique identifiers)
        full_path = os.path.join(directory,experiment, intermediate, plate)
        for file in os.listdir(full_path):
            if file.endswith('distance.csv'):  # only care about distance and velocity metrics
                well = file.split('_')[0]
                dist_df = pd.read_csv(os.path.join(full_path, file))
                dist_df['Experiment'] = experiment # add metadata to new df
                dist_df['Plate'] = plate
                dist_df['Well'] = well
                complete_dist_df = pd.concat([complete_dist_df, dist_df], axis=0) # add to full results df

            if file.endswith('velocity.csv'):   # repeat for second metric
                well = file.split('_')[0]
                vel_df = pd.read_csv(os.path.join(full_path, file))
                vel_df['Experiment'] = experiment
                vel_df['Plate'] = plate
                vel_df['Well'] = well
                complete_velo_df = pd.concat([complete_velo_df, vel_df], axis=0)

    # leftjoin the two individual metrics df's to end up with one table per well
    master_df = pd.merge(complete_velo_df, complete_dist_df, on=['Experiment', 'Plate', 'Well', 'Track Number'], how='left')

    # then combine well level results to a single file 
    fix_order = [2,3,4,0,1,5,6] # reorder columns
    master_df = master_df.iloc[:, fix_order]

    return master_df
        


# add experiment treatment info to results
def add_treatment_info(master_df):
    treatment_table = pd.read_csv(os.path.join(directory, experiment, 'treatment_table_test.csv'))
    master_df_labeled = pd.merge(master_df, treatment_table, on=['Well', 'Plate'], how='inner').sort_values(by=sort_by)
    return master_df_labeled


# export concatenated results file
def export_concat_file(master_df_labeled):
    export_file_name = 'concatenated_chemotaxis_results.csv'
    export_path = os.path.join(directory, experiment, export_file_name)
    master_df_labeled.to_csv(export_path, index=False)



# call main function
if __name__ == "__main__":
    main()

