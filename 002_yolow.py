# note that yolo_zs_1 python env should be used here

import pandas as pd
import numpy as np
import argparse
import cv2
import supervision as sv

from tqdm import tqdm
from inference.models import YOLOWorld

import mmcv
from mmengine.utils import track_iter_progress

parser = argparse.ArgumentParser("002 Detect Firearms with Yolo World")
parser.add_argument("--verbose", help="run with extended output", action = 'store_true')
parser.add_argument("--testing_mode", help="run in testing mode (only on two images)", action = 'store_true')
parser.add_argument("--output_fpath", help="name of file for script to write to", type=str)
parser.add_argument("--input_fpath", help="name of post level sheet for script to read", type=str)
args = parser.parse_args()

verbose = args.verbose

model = YOLOWorld(model_id="yolo_world/l")

classes = ["person",
	   "gun"]

model.set_classes(classes)

confidence = 0.01
figs = True

def get_video_demo(video_fpath, video_fpath_out):

	frame_generator = sv.get_video_frames_generator(video_fpath)
	video_info = sv.VideoInfo.from_video_path(video_fpath)

	width, height = video_info.resolution_wh
	frame_area = width * height

	with sv.VideoSink(target_path=video_fpath_out, video_info=video_info) as sink:
		for frame in tqdm(frame_generator, total=video_info.total_frames):
			results = model.infer(frame, confidence=confidence)
			detections = sv.Detections.from_inference(results).with_nms(threshold=0.1)
			detections = detections[(detections.area / frame_area) < 0.10]

			annotated_frame = frame.copy()
			annotated_frame = BOUNDING_BOX_ANNOTATOR.annotate(annotated_frame, detections)
			annotated_frame = LABEL_ANNOTATOR.annotate(annotated_frame, detections)
			sink.write_frame(annotated_frame)

def get_image_demo(image_fpath, image_fpath_out):

	image = cv2.imread(image_fpath)
	results = model.infer(image, confidence = confidence)

	detections = sv.Detections.from_inference(results)
	detected_classes = [detections[i].data['class_name'] for i in range(len(detections))]

	annotated_image = image.copy()
	annotated_image = BOUNDING_BOX_ANNOTATOR.annotate(annotated_image, detections)
	annotated_image = LABEL_ANNOTATOR.annotate(annotated_image, detections)

	cv2.imwrite(image_fpath_out, annotated_image)

def get_image_classification(image_fpath):

    try:
        image = cv2.imread(image_fpath)
        results = model.infer(image, confidence = confidence)

        detections = sv.Detections.from_inference(results)
        detected_classes = [detections[i].data['class_name'] for i in range(len(detections))]

        return 1 if 'gun' in detected_classes else 0

    except:
        return np.nan

#######
# create demo figs with yolow
#######

if(figs):

	BOUNDING_BOX_ANNOTATOR = sv.BoundingBoxAnnotator(thickness=2)
	LABEL_ANNOTATOR = sv.LabelAnnotator(text_thickness=2, text_scale=1, text_color=sv.Color.BLACK)
	
	image_fpaths = ["demo/2022-02-21_23-56-16_UTC_2-nancy_mace.jpg",
			"demo/2023-01-23_18-49-14_UTC_3-kat_cammack.jpg",
			"demo/2022-08-16_00-55-59_UTC_1-lauren_boebert.jpg",
	#		"demo/2021-11-23_22-00-51_UTC-mayara_flores.jpg",
	#		"demo/2020-09-09_19-46-24_UTC-lisa_mclain.jpg",
	#		"demo/2022-04-23_20-29-34_UTC-ashley_hinson.jpg",
	#		"demo/2022-11-26_17-11-17_UTC-mtg.jpg",
	#		"demo/2023-10-10_13-55-54_UTC-mary_miller.jpg",
	#		"demo/2020-05-08_22-57-17_UTC-yvette_herrel.jpg",
	#		"demo/2020-06-07_17-24-00_UTC-claudia_tenny.jpg",
	#		"demo/2024-01-25_19-34-08_UTC_1-beth_vanduyne.jpg"
		       ]

	video_fpaths = ["demo/2020-01-18_02-45-56_UTC-mtg.mp4",
			#"",
			#""
		       ]

	image_counter = 0
	video_counter = 0

	for image_fpath in image_fpaths:
		get_image_demo(image_fpath = image_fpath, image_fpath_out = "figs/fig_1/" + "target_" + str(image_counter) + ".jpg")
		image_counter = image_counter + 1

	for video_fpath in video_fpaths:
		get_video_demo(video_fpath = video_fpath, video_fpath_out = "figs/fig_a1/" + "target_" + str(video_counter) + ".mp4")
		video_counter = video_counter + 1

df = pd.read_csv(args.input_fpath)

#######
# run yolow
#######

if(args.testing_mode):
	df = df.head(5)

tqdm.pandas()  # Initialize tqdm for progress bars
df['gun'] = df['media_fpath'].progress_apply(get_image_classification)

#######
# export df
#######

df.to_pickle(args.output_fpath)
