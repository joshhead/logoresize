def getNewWidthHeight(boundsWidth, boundsHeight, padding, rectWidth, rectHeight)
  # paddedWidth and paddedHeight: demensions once padding is removed on all sides
  paddedWidth = boundsWidth - (2 * padding)
  paddedHeight = boundsHeight - (2 * padding)

  boundsRatio = paddedWidth.to_f / paddedHeight
  rectRatio = rectWidth.to_f / rectHeight

  if (boundsRatio > rectRatio)
    # pillarbox
    newHeight = paddedHeight
    newWidth = paddedHeight * rectRatio
  else
    # letterbox
    newHeight = paddedWidth / rectRatio
    newWidth = paddedWidth
  end

  return [newWidth.to_i, newHeight.to_i]
end

# Convenience method so fuzz property doesn't have to get messed up
def getTrimmedImage(orig, fuzz=nil)
  oldFuzz = orig.fuzz
  if (fuzz)
    orig.fuzz = fuzz
  end
  trimmed = orig.trim
  orig.fuzz = oldFuzz
  return trimmed
end

# Return an image that of width x height dimensions
# Based on the average color from the rectangle at x, y
# and of size w x h in the original image.
def getBackgroundImage(orig, width, height, x, y, w, h)
  cropped = orig.crop(x, y, w, h)
  onePx = cropped.scale(1,1)
  background = onePx.scale(width, height)
  cropped.destroy!
  onePx.destroy!
  return background
end

def createThumbnail(blob, width, height, padding)
  orig = Magick::ImageList.new.from_blob(blob)
  trimmedImg = getTrimmedImage(orig, "2%")
  scaledWidth, scaledHeight =
    getNewWidthHeight(width, height, padding, trimmedImg.columns, trimmedImg.rows)
  scaledImg = trimmedImg.resize(scaledWidth, scaledHeight)
  bgImg = getBackgroundImage(orig, width, height, 0, 0, 3, 3)
  thumbnail = bgImg.composite(scaledImg, Magick::CenterGravity, Magick::OverCompositeOp)
  [orig, trimmedImg, scaledImg, bgImg].each { |img| img.destroy! }
  return thumbnail
end
