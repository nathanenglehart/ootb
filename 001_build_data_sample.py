import pandas as pd
import numpy as np
import os
import re
import shutil
import argparse
import json
import lzma

parser = argparse.ArgumentParser("001 Process Instagram Data")
parser.add_argument("--verbose", help="run with extended output", action = 'store_true')
parser.add_argument("--output_fpath", help="name of file for script to write to", type=str)
parser.add_argument("--input_dir_path", help="name of directory containing rep account folders", type=str)
parser.add_argument("--input_ods_fpath", help="name of rep level ods file", type=str)
parser.add_argument("--input_ods_sheet_name", help="sheet name in rep level ods file", type=str)
args = parser.parse_args()

verbose = args.verbose

df_reference = pd.read_excel(args.input_ods_fpath, sheet_name = args.input_ods_sheet_name)
df_reference['district'] = df_reference['district_118']
df_reference['instagram 1'] = df_reference['instagram 1'].str.lower()
df_reference['instagram 2'] = df_reference['instagram 2'].str.lower()
df_reference['instagram 3'] = df_reference['instagram 3'].str.lower()

#directory = "/media/data3/images/ig"
directory = args.input_dir_path
accounts = os.listdir(directory)

post_media = []
post_media_fpath = []
post_text = []
post_text_fpath = []
post_json_fpath = []
post_account = []
post_date = []

post_uniqueid = []
post_woman = []
post_party = []

for account in accounts:
	if((df_reference["instagram 1"] == account).any() | (df_reference["instagram 2"] == account).any() | (df_reference["instagram 3"] == account).any()):

		posts = os.listdir(directory + "/" + account)

		txts = [post for post in posts if ".txt" in post]
		jpgs = [post for post in posts if ".jpg" in post]
		mp4s = [post for post in posts if ".mp4" in post]
		jsons  = [post for post in posts if ".json.xz" in post]

		jpgs_fpath = [os.path.join(directory + "/" + account,jpg) for jpg in jpgs]
		jpgs_text = []
		jpgs_json = []

		mp4s_fpath = [os.path.join(directory + "/" + account,mp4) for mp4 in mp4s]
		mp4s_text = []
		mp4s_json = []

		jpg_dates = []
		mp4_dates = []

		num_posts = len(jpgs) + len(mp4s)

		acct = [account] * num_posts

		for jpg in jpgs:
			jpg_name = re.search("[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}",jpg).group(0)
			date = jpg_name[0:10]
			jpg_text = ""
			jpg_json = ""
			#for txt in txts:
			#	if(jpg_name in txt):
			#		jpg_text = txt	
			#		break
			jpg_text = jpg_name + "_UTC.txt"
			jpg_json = jpg_name + "_UTC.json.xz"
			jpgs_text.append(jpg_text)
			jpgs_json.append(jpg_json)
			jpg_dates.append(date)
		
		for mp4 in mp4s:
			mp4_name = re.search("[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}",jpg).group(0)
			date = mp4_name[0:10]
			mp4_text = ""
			mp4_json = ""
			mp4_text = mp4_name + "_UTC.txt"
			mp4_json = mp4_name + "_UTC.json.xz"
			mp4s_text.append(mp4_text)
			mp4s_json.append(mp4_json)
			mp4_dates.append(date)	

		jpg_txts_fpath = [os.path.join(directory + "/" + account, txt) for txt in jpgs_text]
		jpg_jsons_fpath = [os.path.join(directory + "/" + account, json) for json in jpgs_json]
		mp4_txts_fpath = [os.path.join(directory + "/" + account, txt) for txt in mp4s_text]
		mp4_jsons_fpath = [os.path.join(directory + "/" + account, json) for json in mp4s_json]	

		post_date = post_date + jpg_dates + mp4_dates
		post_media = post_media + jpgs + mp4s
		post_media_fpath = post_media_fpath + jpgs_fpath + mp4s_fpath
		post_text = post_text + jpgs_text + mp4s_text
		post_text_fpath = post_text_fpath + jpg_txts_fpath + mp4_txts_fpath
		post_json_fpath = post_json_fpath + jpg_jsons_fpath + mp4_jsons_fpath
		post_account = post_account + acct

		if(verbose):
			print("account:",account)

		if((df_reference["instagram 1"] == account).any()):
			df_account = df_reference[df_reference["instagram 1"] == account]
		elif((df_reference["instagram 2"] == account).any()):
			df_account = df_reference[df_reference["instagram 2"] == account]
		elif((df_reference["instagram 3"] == account).any()):
			df_account = df_reference[df_reference["instagram 3"] == account]

		uniqueid = df_account['uniqueid'].values[0]
		woman = df_account['woman'].values[0]
		party = df_account['party'].values[0]

		post_uniqueid = post_uniqueid + ([uniqueid] * num_posts)
		post_woman = post_woman + ([woman] * num_posts)
		post_party = post_party + ([party] * num_posts)

df = pd.DataFrame({'media_id':		post_media,
		   'media_fpath': 	post_media_fpath,
		   'text':		post_text,
		   'text_fpath': 	post_text_fpath,
		   'json_fpath': 	post_json_fpath,
		   'acct':		post_account,
		   'date':		post_date,
		   'uniqueid':		post_uniqueid,
		   'party':		post_party,
		   'woman':		post_woman}
		   )

def read_txt_file(fpath):
	try:
		with open(fpath, 'r') as file:
			content = file.read()
		return content
	except:
		return ""

def read_json_file(fpath):
	try:
		with lzma.open(fpath, mode = 'rt', encoding = 'utf-8') as file:
			content = json.load(file)
		return content	
	except:
		return ""

def read_json_likes(fpath):
	try:
		with lzma.open(fpath, mode = 'rt', encoding = 'utf-8') as file:
			content = json.load(file)
		return content['node']['edge_media_preview_like']['count']	
	except:
		return np.nan

def read_json_comments(fpath):
	try:
		with lzma.open(fpath, mode = 'rt', encoding = 'utf-8') as file:
			content = json.load(file)
		return content['node']['comments']	
	except:
		return np.nan

if(verbose):
	print("adding text content column")

df['text_content'] = df['text_fpath'].apply(read_txt_file)

if(verbose):
	print("reading json content")

#df['json_content'] = df['json_fpath'].apply(read_json_file)
#df['likes'] = df['json_fpath'].apply(read_json_likes)
#df['comments'] = df['json_fpath'].apply(read_json_comments)

if(verbose):
	print("writing to csv")

df.to_csv(args.output_fpath)
