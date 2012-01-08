require 'rubygems'
require 'sinatra'
require 'net/http'
require 'RMagick'
require 'logothumb'

get '/' do
  "try visiting /logoresize/?image=http://example.com/img.png&width=200&height=100&padding=20"
end

get '/logoresize/?' do
  uri = params['image']
  width = params['width'].to_i
  height = params['height'].to_i
  padding = params['padding'].to_i

  content_type 'image/png'
  headers 'Content-Disposition' => "inline; filename=#{File.basename(uri)}"
  begin
    img = create_thumbnail(Net::HTTP.get(URI.parse(uri)), width, height, padding).to_blob
  rescue
    return create_thumbnail(Magick::ImageList.new("error.png").to_blob, width, height, padding).to_blob
  end
end
