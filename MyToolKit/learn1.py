from pycocotools.coco import COCO
import numpy as np
import skimage.io as io
import matplotlib.pyplot as plt
import pylab
pylab.rcParams['figure.figsize'] = (10.0, 8.0)

# initial the directory variable
dataDir = '..'

trainDataType = 'train2014'
trainAnnFile = '%s/annotations/instances_%s.json'%(dataDir, trainDataType)

#valDataType = 'val2014'
#valAnnFile = '%s/annotations/instances_%s.json'%(dataDir, valDataType)

# NO annotations for test set
#testDataType = 'test2014'
#testAnnFile = '%s/annotations/instance_%s.json'%(dataDir, testDataType)


# initialize COCO API for instance annotations
train = COCO(trainAnnFile)
#val = COCO(valAnnFile)
#test = COCO(testAnnFile)

cats = train.loadCats(train.getCatIds())
nms = [cat['name'] for cat in cats]
print 'COCO train categories:\n\n', ' '.join(nms)

# here we need set() to eliminate the repeated supercategories, since
# many categories may have the same supercategory
nms = set([cat['supercategory'] for cat in cats]) #test=[cat['supercategory'] for cat in cats]
print 'COCO supercategoires :\n', ' '.join(nms)

# get all images of some given category
catIds = train.getCatIds(catNms=['person', 'dog', 'skateboard'])
imgIds = train.getImgIds(catIds=catIds)

# load and display image
for i in range(0, 5):
	img = train.loadImgs(imgIds[np.random.randint(0, len(imgIds))])[0]
	I = io.imread('%s/images/%s/%s'%(dataDir, trainDataType, img['file_name']))
	print '%s/images/%s/%s'%(dataDir, trainDataType, img['file_name'])
	plt.figure()
	plt.imshow(I)
	plt.show()

plt.imshow(I)
annIds = train.getAnnIds(imgIds=img['id'], catIds=catIds, iscrowd=None)
anns = train.loadAnns(annIds)
train.showAnns(anns)

# for caption annotations
annFile = '%s/annotations/captions_%s.json'%(dataDir, trainDataType)
caps = COCO(annFile)

annIds = caps.getAnnIds(imgIds=img['id'])
anns = caps.loadAnns(annIds)
caps.showAnns(anns)
plt.imshow(I)
plt.show()
