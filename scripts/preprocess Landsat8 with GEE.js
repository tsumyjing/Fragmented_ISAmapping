/**assets links: 
https://code.earthengine.google.com/?asset=users/LRP/Liping
*/

/**
 * Function to mask clouds based on the pixel_qa band of Landsat 8 SR data.
 * @param {ee.Image} image input Landsat 8 SR image
 * @return {ee.Image} cloudmasked Landsat 8 image
 */
function maskL8sr(image) {
  // Bits 3 and 5 are cloud shadow and cloud, respectively.
  var cloudShadowBitMask = (1 << 3);
  var cloudsBitMask = (1 << 5);
  // Get the pixel QA band.
  var qa = image.select('pixel_qa');
  // Both flags should be set to zero, indicating clear conditions.
  var mask = qa.bitwiseAnd(cloudShadowBitMask).eq(0)
                 .and(qa.bitwiseAnd(cloudsBitMask).eq(0));
  return image.updateMask(mask);
}

var dataset = ee.ImageCollection('LANDSAT/LC08/C01/T1_SR')
                  .filterDate('2015-01-01', '2015-12-31')
                  .filterBounds(table)
                  .map(maskL8sr)
                  .median()
                  .clip(table);
print(dataset);

var visParams = {
  bands: ['B4', 'B3', 'B2'],
  min: 0,
  max: 3000,
  gamma: [0.95, 1.1, 1]
};

Map.setCenter(109.134520,26.231977, 9);
Map.addLayer(dataset, visParams,'lipingclip');

Export.image.toDrive({
  image: dataset,
  region: table,
  description: 'sat15_com',
  scale: 30,
  crs: 'EPSG:32648'
});
