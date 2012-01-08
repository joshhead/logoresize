# Josh Headapohl 2012

module LogoThumb

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

  # RMagick may have better ways to get at post-crop offset information.
  # I couldn't find it, so I'm parsing it from the Image.inspect string.
  # Will return nil if parsing fails.
  def get_trim_properties(image)
    if (image.inspect =~ /(\d+)x(\d+) (\d+)x(\d+)\+(\d+)\+(\d+)/)
      prop = Hash.new
      prop[:trimmed_width] = $1.to_i
      prop[:trimmed_height] = $2.to_i
      prop[:orig_width] = $3.to_i
      prop[:orig_height] = $4.to_i
      prop[:offset_x] = $5.to_i
      prop[:offset_y] = $6.to_i
      return prop
    else
      return nil
    end
  end

  # The whole point of this method is to handle logos
  # that have a border on some but not all sides.
  #
  # Taking a rectangle instead of a point gives a better
  # color approximation if the pixels in the colored border
  # are almost but not exactly the same. We will take the
  # average color of the whole area.
  def get_bg_sample_rect(trim_properties)
    if (trim_properties.nil?)
      # Make a blind guess.
      # Any corner should be a reasonable bet
      # If there was a border at all.
      rect = Hash.new
      rect[:x] = 0
      rect[:y] = 0
      rect[:w] = 1
      rect[:h] = 1
      return rect
    else
      # Look at some rectangles of color
      # that were cropped out of the original image.
      # Pick the biggest one.
      tp = trim_properties
      rects = Array.new
      # Left side
      # |x--|
      # |x  |
      # |x__|
      rects << {
        :x => 0,
        :y => 0,
        :w => tp[:offset_x],
        :h => tp[:orig_height]
      }
      # Right side
      # |--x|
      # |  x|
      # |__x|
      rects << {
        :x => tp[:offset_x] + tp[:trimmed_width],
        :y => 0,
        :w => tp[:orig_width] - (tp[:trimmed_width] + tp[:offset_x]),
        :h => tp[:orig_height]
      }
      # Top area
      # |xxx|
      # |   |
      # |___|
      rects << {
        :x => 0,
        :y => 0,
        :w => tp[:orig_width],
        :h => tp[:offset_y]
      }
      # Bottom area
      # |---|
      # |   |
      # |xxx|
      rects << {
        :x => 0,
        :y => tp[:offset_y] + tp[:trimmed_height],
        :w => tp[:orig_width],
        :h => tp[:orig_height] - (tp[:trimmed_height] + tp[:offset_y])
      }
      # Return biggest rect
      return rects.sort { |a, b| (b[:w] * b[:h]) <=> (a[:w] * a[:h]) }.first
    end
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

  # blob should be a string containing binary image data.
  def create_thumbnail(blob, width, height, padding)
    width = 1 if (width < 1)
    height = 1 if (height < 1)
    if (2 * padding > [width, height].min)
      padding = ([width, height].min / 4)
    end
    orig = Magick::ImageList.new.from_blob(blob)
    trimmed_img = get_trimmed_image(orig, "2%")
    scaled_width, scaled_height =
      get_new_width_height(width, height, padding, trimmed_img.columns, trimmed_img.rows)
    scaled_img = trimmed_img.resize(scaled_width, scaled_height)
    if (orig.rows == trimmed_img.rows && orig.columns == trimmed_img.columns)
      if (scaled_img.format == "PNG")
        bg_color = "transparent"
      else
        # Setting a transparent background for a JPEG results in a black background.
        # I think white is less ugly here.
        bg_color = "white"
      end
      bg_img = Magick::Image.new(width, height) {self.background_color = bg_color; self.format = scaled_img.format }
    else
      rect = get_bg_sample_rect(get_trim_properties(trimmed_img))
      bg_img = get_background_image(orig, width, height, rect[:x], rect[:y], rect[:w], rect[:h])
    end
    thumbnail = bg_img.composite(scaled_img, Magick::CenterGravity, Magick::OverCompositeOp)
    [orig, trimmed_img, scaled_img, bg_img].each { |img| img.destroy! }
    return thumbnail
  end

  def get_file(uri)
    Net::HTTP.get(URI.parse(uri))
  end

end
