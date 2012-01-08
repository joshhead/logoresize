def get_new_width_height(bounds_width, bounds_height, padding, rect_width, rect_height)
  # padded_width and padded_height: demensions once padding is removed on all sides
  padded_width = bounds_width - (2 * padding)
  padded_height = bounds_height - (2 * padding)

  bounds_ratio = padded_width.to_f / padded_height
  rect_ratio = rect_width.to_f / rect_height

  if (bounds_ratio > rect_ratio)
    # pillarbox
    new_height = padded_height
    new_width = padded_height * rect_ratio
  else
    # letterbox
    new_height = padded_width / rect_ratio
    new_width = padded_width
  end

  return [new_width.to_i, new_height.to_i]
end

# Convenience method so fuzz property doesn't have to get messed up
def get_trimmed_image(orig, fuzz=nil)
  old_fuzz = orig.fuzz
  if (fuzz)
    orig.fuzz = fuzz
  end
  trimmed = orig.trim
  orig.fuzz = old_fuzz
  return trimmed
end

# Return an image that of width x height dimensions
# Based on the average color from the rectangle at x, y
# and of size w x h in the original image.
def get_background_image(orig, width, height, x, y, w, h)
  cropped = orig.crop(x, y, w, h)
  one_px = cropped.scale(1,1)
  background = one_px.scale(width, height)
  cropped.destroy!
  one_px.destroy!
  return background
end

def create_thumbnail(blob, width, height, padding)
  orig = Magick::ImageList.new.from_blob(blob)
  trimmed_img = get_trimmed_image(orig, "2%")
  scaled_width, scaled_height =
    get_new_width_height(width, height, padding, trimmed_img.columns, trimmed_img.rows)
  scaled_img = trimmed_img.resize(scaled_width, scaled_height)
  bg_img = get_background_image(orig, width, height, 0, 0, 3, 3)
  thumbnail = bg_img.composite(scaled_img, Magick::CenterGravity, Magick::OverCompositeOp)
  [orig, trimmed_img, scaled_img, bg_img].each { |img| img.destroy! }
  return thumbnail
end
