
import sys
from PIL import Image
from PIL import ImageSequence
import numpy as np
import os
from os import listdir
from stardist.models import StarDist2D
from csbdeep.utils import normalize
from csbdeep.io import save_tiff_imagej_compatible

INIMG=sys.argv[1]

INDIR=INIMG+"/"

INFILES=os.listdir(INDIR)

model = StarDist2D.from_pretrained('2D_versatile_fluo')

Image.MAX_IMAGE_PIXELS = 412400000

for INFILE in INFILES:
	if INFILE[-4:] != '.tif':
		continue
	INPUTS = INDIR + INFILE
	IMG=Image.open(INPUTS)
	IMG_channels=ImageSequence.Iterator(IMG)
	DAPI_array=np.array(IMG_channels[1])
	labels,polygons=model.predict_instances(normalize(DAPI_array))
	OUTFILE=INPUTS[:-4]
	save_tiff_imagej_compatible('%s_labels.tif' % OUTFILE, labels, axes='YX')
