# This script is used for extracting images from coco dataset
# And will generate the train.txt and test.txt for fine-tuning in caffe
from pycocotools.coco import COCO
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
foodCategoryIds = []
foodImageIds = []

for cat in cats:
	if cat['supercategory'] == 'food':
		foodCategory.append(cat['name'])
		print cat['name']

# get all food categories
foodCategoryIds = coco.getCatIds(foodCategory) 
print "foodCategoryId has %d items"% (len(foodCategoryIds))
print "foodCategoryIds are " + str(foodCategoryIds)

dstdir = '../JPEGImages'
allImagePath = '/data3/users/cliu2/caffe/data/test/images' 

file_conf_name = '%s.txt'%(dataType)
file = open(file_conf_name, "wb")

# copy images and write .txt file
for cat in foodCategoryIds:
	 foodImageIds = coco.getImgIds(catIds=cat) #must add catIds=
	 print "foodImageId has %d items"%(len(foodImageIds))

	 path = '%s/%s/'%(dstdir, foodCategory[cat-foodCategoryIds[0]])
	 print path

	 if not os.path.exists(path):
		os.makedirs(path)
	
	 for i in foodImageIds:
		img = coco.loadImgs(i)[0]
		img_name = '%s/images/%s/%s'%(dataDir,dataType,img['file_name'])
	#	print img_name

		errors = []
		try:
			if not os.path.exists(img_name):
				print 'ERROR, the image is not in the folder!'

			shutil.copy(img_name, allImagePath) # for Caffe training
			shutil.copy(img_name, path)
		except (IOError, os.error) as why:
            		errors.append((srcname, dstname, str(why)))
			print 'ERROR!'
		except Error as err:
            		errors.extend(err.args[0])
			print 'ERROR!'

		fileList = '%s/%s %d\n'%(allImagePath,img['file_name'], cat-foodCategoryIds[0])
		file.write(fileList)


file.close()
