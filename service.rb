# Josh Headapohl 2012

require 'rubygems'
require 'sinatra'
require 'net/http'
require 'RMagick'
require 'logothumb'
include LogoThumb

get '/' do
  "try visiting /logoresize/?image=http://example.com/img.png&width=200&height=100&padding=20"
end

get '/logoresize/?' do
  uri = params['image']
  width = params['width'].to_i
  height = params['height'].to_i
  padding = params['padding'].to_i

  begin
    img = create_thumbnail(Net::HTTP.get(URI.parse(uri)), width, height, padding)
    if (img.format == "JPEG")
      content_type 'image/jpeg'
    elsif (img.format == "PNG")
      content_type 'image/png'
    else
      content_type 'application/octet-stream'
    end
    headers 'Content-Disposition' => "attachment; filename=#{File.basename(uri)}"
    return img.to_blob
  rescue
    content_type 'image/png'
    headers 'Content-Disposition' => "inline; filename=#{File.basename(uri)}"
    return create_thumbnail(Magick::ImageList.new("error.png").to_blob, width, height, padding).to_blob
  end
end
