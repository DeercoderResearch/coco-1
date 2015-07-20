from xml.dom import minidom, Node 

## img_name:  image name
## food_type: food type
## img_width: image size's width;  img_height: image size's height
## bounding box: [left_x, left_y, right_x, right_y], top-left and right-bottom coordinates
def write_to_file(img_name,food_type, file_name, img_width, img_height,left_x, left_y, right_x, right_y):
  
	doc = minidom.Document() 
	 
	# generate the annotation 
	annotation = doc.createElement('annotation') 
	doc.appendChild(annotation) 
	 
	# the folder 
	folder = doc.createElement('folder') 
	folder.appendChild(doc.createTextNode("VOC2007")) 
	annotation.appendChild(folder) 
	  
	# the filename 
	filename = doc.createElement("filename") 
	filename.appendChild(doc.createTextNode(img_name))
	annotation.appendChild(filename) 

	# size
	size = doc.createElement('size')
	width = doc.createElement('width')
	height = doc.createElement('height')
	depth = doc.createElement('depth')

	width.appendChild(doc.createTextNode(img_width))
	height.appendChild(doc.createTextNode(img_height))
	depth.appendChild(doc.createTextNode('3'))

	size.appendChild(width)
	size.appendChild(height)
	size.appendChild(depth)
	annotation.appendChild(size)
	 
	# segmented
	segmented = doc.createElement('segmented')
	segmented.appendChild(doc.createTextNode("0"))
	annotation.appendChild(segmented) 

	# object 
	object = doc.createElement('object')
	name = doc.createElement('name')
	pose = doc.createElement('pose')
	truncated = doc.createElement('truncated')
	difficult = doc.createElement('difficult')
	bndbox = doc.createElement('bndbox')
	xmin = doc.createElement('xmin')
	ymin = doc.createElement('ymin')
	xmax = doc.createElement('xmax')
	ymax = doc.createElement('ymax')

	name.appendChild(doc.createTextNode(food_type))
	pose.appendChild(doc.createTextNode('Unspecified'))
	truncated.appendChild(doc.createTextNode('0'))
	difficult.appendChild(doc.createTextNode('0'))
	xmin.appendChild(doc.createTextNode(left_x))
	ymin.appendChild(doc.createTextNode(left_y))
	xmax.appendChild(doc.createTextNode(right_x))
	ymax.appendChild(doc.createTextNode(right_y))
	 
	bndbox.appendChild(xmin)
	bndbox.appendChild(ymin)
	bndbox.appendChild(xmax)
	bndbox.appendChild(ymax)

	object.appendChild(name)
	object.appendChild(pose)
	object.appendChild(truncated)
	object.appendChild(difficult)
	object.appendChild(bndbox)
	annotation.appendChild(object)
	 
	#print doc.toprettyxml() 

	## add last processing to avoid the <?xml=xxxx> area
	lines = doc.toprettyxml()
	firstlineEndIndex = lines.find(">")
#	print firstlineEndIndex
	new_file_content = lines[firstlineEndIndex+2:]
#	print new_file_content

	# write to xml file
	f = open(file_name, "w")
	f.write(new_file_content)
	f.close()

