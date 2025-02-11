import numpy as np
import pandas as pd
import os
import shutil
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
from datetime import datetime

olive_green = "#808000"
dark_blue = "#00008B"
teal = "#008080"
dark_green = "#006400"
gray = "#4B4B4B"
sky_blue = "#87CEEB"
washu_red = "#A51417"

parser = argparse.ArgumentParser("004 Testing")
parser.add_argument("--verbose", help="run with extended output", action = 'store_true')
parser.add_argument("--output_fpath", help="name of file for script to write to", type=str)
parser.add_argument("--input_fpath", help="name of post level sheet for script to read", type=str)
args = parser.parse_args()

df = pd.read_pickle(args.input_fpath)

df['post_id'] = pd.factorize(df['media_fpath'].str.replace(r'/[^/]+\.jpg$', '/', regex=True) + df['media_id'].str.replace(r'_(\d{1,2})(?=\.\w+$)', '', regex=True))[0] 

df = df[['media_id',
         'media_fpath',
         'text',
         'text_fpath',
	 'text_content',
         'json_fpath',
         'acct',
         'woman',
         'date',
         'uniqueid',
         'gun',
	 'party',
         'post_id']] 

df_image_labels_1 = pd.read_csv("labels/image_labels_1.csv")
df_image_labels_2 = pd.read_csv("labels/image_labels_2.csv")
df_image_labels_1 = df_image_labels_1[['media_fpath','Label']]
df_image_labels_2 = df_image_labels_2[['media_fpath','Label']]

df_image_labels = pd.concat([df_image_labels_1,df_image_labels_2], axis=0) # Image, Label
df = pd.merge(df,df_image_labels, on = 'media_fpath', how = 'left', indicator = True)
df.loc[df['_merge'] == 'both', 'gun'] = df['Label']

df = df.drop(columns = ['_merge','Label'])
df_image_labels_strict_1 = pd.read_csv("labels/image_labels_strict_b4.csv")
df_image_labels_strict_2 = pd.read_csv("labels/image_labels_strict_b5.csv")
df_image_labels_strict = pd.concat([df_image_labels_strict_1,df_image_labels_strict_2], axis=0)

#df_image_labels_strict.columns = ['media_id','Label','media_fpath']

df = pd.merge(df,df_image_labels_strict, on = 'media_fpath', how = 'left', indicator = True)

df['gun_strict'] = 0
df.loc[df['_merge'] == 'both', 'gun_strict'] = df['Label']

df['gun_post'] = df.groupby('post_id')['gun'].transform(lambda x : 1 if x.max() == 1 else 0)
df['gun_strict_post'] = df.groupby('post_id')['gun_strict'].transform(lambda x : 1 if x.max() == 1 else 0)
print("strict post:",df['gun_strict_post'].sum())

# check format
print(df[['uniqueid','post_id','gun_post','gun_strict_post']].head(40))
print(df[['uniqueid','post_id','gun_post','gun_strict_post']].tail(40))

#df['woman']

df.to_csv("df_yolow_clean_1.csv")

df_rep = df.groupby('uniqueid').agg(
	gun = ('gun','sum'),
	gun_strict = ('gun_strict','sum'),
	gun_post = ('gun_post','sum'),
	gun_strict_post = ('gun_strict_post','sum'),
	woman = ('woman','first'),
	party = ('party', 'first'),
	first_post_date = ('date','min'),
	last_post_date = ('date','max'),
	num_media  = ('uniqueid','size'),
	num_posts = ('post_id', 'nunique')
).reset_index()

df_rep = df_rep[df_rep['uniqueid'] != "Smith MO-8"] # no posts

df_rep.to_csv("df_yolow_clean_rep.csv")

exit()























df_rep['first_post_date'] = pd.to_datetime(df_rep['first_post_date'])
df_rep['last_post_date'] = pd.to_datetime(df_rep['last_post_date'])
df_rep['days_between'] = (df_rep['last_post_date'] - df_rep['first_post_date']).dt.days
print(df_rep[df_rep['days_between'] == 0]['uniqueid'])

num_reps = df_rep.shape[0]
num_m_reps = df_rep[df_rep['woman'] == 0].shape[0]
num_w_reps = df_rep[df_rep['woman'] == 1].shape[0]

df_rep.loc[df_rep['rep'] == "Mace", 'gun'] = df_rep['gun'] + 1 # due to error noted above
df_rep['percent gun'] = df_rep['gun_post'] / df_rep['gun_post'].sum()
df_rep['percent gun'] = df_rep['percent gun'].round(4)
# df_rep['percent gun'] = df_rep['gun'] / df_rep['count'] # another way to think about things but makes little substantive sense when analyzing results
# prob better to think about 

#####################################

women_gun_perc = df_rep[df_rep['woman'] == 1]['percent gun'].sum()

print("women_gun_perc = ", women_gun_perc)

boebert = df_rep[df_rep['rep'] == "Boebert"]['percent gun'].sum()
green = df_rep[df_rep['rep'] == "Green"]['percent gun'].sum()
flores = df_rep[df_rep['rep'] == "Flores"]['percent gun'].sum()
cammack = df_rep[df_rep['rep'] == "Cammack"]['percent gun'].sum()
stefanik = df_rep[df_rep['rep'] == "Stefanik"]['percent gun'].sum()
mace = df_rep[df_rep['rep'] == "Mace"]['percent gun'].sum()
salazar = df_rep[df_rep['rep'] == "Salazar"]['percent gun'].sum()

print("boebert + green + flores + cammack + stefanik + mace + salazar = ", boebert + green + flores + cammack + stefanik + mace + salazar)

mean_value = df_rep['percent gun'].mean()
median_value = df_rep['percent gun'].median()

print("total reps = ", df_rep.shape[0])
print("women reps = ", df_rep[df_rep['woman'] == 1].shape[0])

print("mean gun posts = ", mean_value)
print("median gun posts = ", median_value)

#####################################


x_axis='percent gun'
y_axis='uniqueid'
woman_color = washu_red #dark_blue
man_color = gray # was 'black'

df_rep_sorted = df_rep.sort_values(by=x_axis, ascending = False)
median_value_idx = np.median(range(len(df_rep_sorted)))

plt.figure(figsize=(20,24))
bars = sns.barplot(x=x_axis, y=y_axis, data=df_rep_sorted, palette='Blues_d', edgecolor=None) # 'Blues_d'

# Add labels at the end of the bars for each representative
for i, (percent, rep, is_woman) in enumerate(zip(df_rep_sorted[x_axis], 
                                                 df_rep_sorted[y_axis], 
                                                 df_rep_sorted['woman'])):
    # Choose the position for the text based on the bar length
    text_x = percent + 0.0001  # Slightly beyond the end of the bar
    color = woman_color if is_woman else man_color
    fontsize = 22 if is_woman else 12

    # Add the representative name as a label at the end of the bar
    plt.text(text_x, i, rep, ha='left', va='center', color=color, fontsize=fontsize)

# Add horizontal lines for mean and median positions
plt.axhline(y=median_value_idx, color='green', linestyle='--', label=f'Median: {int(median_value_idx)}')
plt.text(df_rep_sorted[x_axis].max() * 1.01, median_value_idx, "Median", ha='right', va='center', color='green', fontsize=22,
         bbox=dict(facecolor='white', edgecolor='green', pad=3))

from matplotlib.patches import Patch
legend_elements = [
    Patch(facecolor=woman_color, edgecolor=woman_color, label='woman representative (N=' + str(num_w_reps) + ')'),
    Patch(facecolor=man_color, edgecolor=man_color, label='man representative (N=' + str(num_m_reps) + ')'),
]
plt.legend(handles=legend_elements, loc='lower right', fontsize=22)

#plt.yticks(range(len(df_rep_sorted)), df_rep_sorted['rep'])
plt.yticks([])

plt.xlabel('Gun Posts / Total Gun Posts', fontsize = 22)
plt.ylabel('Republican Representatives (N=' + str(num_reps) + ')', fontsize = 22)
plt.savefig("fig2.png", dpi = 300)
#plt.show()

df_rep.to_csv('df_rep_clean_1.csv')
