from pycocotools.coco import COCO
from write_xml import write_to_file
import numpy as np
import skimage.io as io
import matplotlib.pyplot as plt
import os
import shutil

dataDir='..'
dataType='val2014'
annFile='%s/annotations/instances_%s.json'%(dataDir,dataType)

coco=COCO(annFile)	# load database
cats=coco.loadCats(coco.getCatIds())
print cats

foodCategory = []
foodCategoryId = []
foodImageId = []

for cat in cats:
	if cat['supercategory'] == 'food':
		foodCategory.append(cat['name'])
		print cat['name']

foodCategoryId = coco.getCatIds(foodCategory)
foodImageId = coco.getImgIds(catIds=foodCategoryId) #must add catIds=
#print len(foodImageId)

dstdir = './JPEGImages/'

# Get all food images and copy them to JPEGImages folders.(#JPEGImage#)
for cat in range(0, len(foodImageId)):
	img = coco.loadImgs(foodImageId[cat])[0]
	img_name = '%s/images/%s/%s'%(dataDir,dataType,img['file_name'])
	#print img_name
	shutil.copy(img_name, dstdir)


# Generate the SegmentationObject/SegmentationClass (#Segmentation#)
dstdir = './SegmentationClass'
dstdir_2 = './SegmentationObject'

# Generate the configuration files for Annotation folders(#Annotation#)
# Move to the above the share the loop of image_names.
for cat in range(0, len(foodImageId)):
	img = coco.loadImgs(foodImageId[cat])[0]
	img_name = os.path.splitext(img['file_name'])[0]
	img_annotation_xml_name ='./Annotations/%s.xml'%(img_name)
	img_annotation_jpg_name ='./JPEGImages/%s.jpg'%(img_name)
#	print img_annotation_xml_name
	file = open(img_annotation_xml_name, "wb")
	# def write_to_file(img_name,food_type, file_name, img_width, img_height,left_x, left_y, right_x, right_y):
	img_width = img['width']
	img_height = img['height']
	
	## Now load annotation in order to get bbox, food type
	ann_id = coco.getAnnIds(imgIds=img['id'])
	print "ann_id" 
	print ann_id
	
	## Note: for one image, there are multiple labels, find the food_label
	ann = coco.loadAnns(ann_id)

	for ann_food in ann:
		ann_cat_id = ann_food['category_id']
		ann_cat = coco.loadCats(ann_cat_id)[0]
		if ann_cat['supercategory'] == 'food':
			print ann_cat['name']	
			food_ann = ann_food
			break
	
	print "annotation"
	print ann_food
	bbox = ann_food['bbox']
	catId = ann_food['category_id']
	cat = coco.loadCats(catId)[0]
	left_x = bbox[0]
	left_y = bbox[1]
	right_x = left_x + bbox[2]
	right_y = left_y + bbox[3]
	food_type = cat['name']


	print img_annotation_jpg_name

	if food_type == 'donut':
		shutil.copy(img_annotation_jpg_name, "./donut/")
	elif food_type == 'cake':
		shutil.copy(img_annotation_jpg_name, "./cake/")
	elif food_type == 'hot dog':
		shutil.copy(img_annotation_jpg_name, "./hotdog/")
	elif food_type == 'sandwich':
		shutil.copy(img_annotation_jpg_name, "./sandwich/")
	elif food_type == 'carrot':
		shutil.copy(img_annotation_jpg_name, "./carrot/")
	elif food_type == 'apple':
		shutil.copy(img_annotation_jpg_name, "./apple/")
	elif food_type == 'orange':
		shutil.copy(img_annotation_jpg_name, "./orange/")
	elif food_type == 'banana':
		shutil.copy(img_annotation_jpg_name, "./banana/")
	elif food_type == 'pizza':
		shutil.copy(img_annotation_jpg_name, "./pizza/")

 	write_to_file(img_annotation_jpg_name, food_type, img_annotation_xml_name, str(img_width), str(img_height), str(left_x), str(left_y), str(right_x), str(right_y))
	file.close()

### ?????? 

# Generat the configuration for ImageSet


img = coco.loadImgs(foodImageId[5])[0]
img_name = '%s/images/%s/%s'%(dataDir,dataType,img['file_name'])
I = io.imread(img_name)
#plt.figure()
#plt.imshow(I)
#plt.show()

# JUST FOR DEBUGGING
print foodCategory
print foodCategoryId	
print foodImageId
print img_name
