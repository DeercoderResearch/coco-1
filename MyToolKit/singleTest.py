#!/usr/bin/env python
from write_xml import write_to_file

# ''' This is just for single test of one function write_to_file
# Because I found that the generated xml is not compatiable with
# original xml, containing the head `<?xml xxx>`, this may harm
# r-cnn code and it crashes when finishing parsing
#'''

write_to_file("aaa.xml", "orange", "stest.xml", "480", "640", "0", "0", "123", "123")
