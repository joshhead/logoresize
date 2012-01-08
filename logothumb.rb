def getNewWidthHeight(boundsWidth, boundsHeight, padding, rectWidth, rectHeight)
  # paddedWidth/paddedHeight: demensions once padding is removed on all sides
  paddedWidth = boundsWidth - (2 * padding)
  paddedHeight = boundsHeight - (2 * padding)

  boundsRatio = paddedWidth.to_f / paddedHeight
  rectRatio = rectWidth.to_f / rectHeight

  if (boundsRatio > rectRatio)
    newHeight = paddedHeight
    newWidth = paddedHeight / rectRatio
  else
    newHeight = paddedHeight * rectRatio
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
