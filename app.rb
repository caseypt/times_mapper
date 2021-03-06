$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'sinatra'
require 'compass'
require 'sass'
require 'haml'
require 'json'
require 'net/http'
require 'date'
require 'yaml'

configure do
  set :haml, {:format => :html5, :escape_html => true}
  set :scss, {:style => :compact, :debug_info => false}
  Compass.add_project_configuration(File.join(Sinatra::Application.root, 'config.rb'))
end

# Serve the requested stylesheet
get '/stylesheets/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss(:"sass/#{params[:name]}")
end

# Redirect index to /!# so we
# can handle pushstate changes
get '/' do
  redirect '/!'
end

# Go to the index
get '/!' do
  haml:index
end

# Go to the index. front-end JS will 
# listen to pop event and perform search
get '/search/:topic' do
  haml:index
end

# Query the nytimes article api
# for the given topic. 
# Return the results in JSON form
get '/query/:topic/:offset' do
  if params[:topic]
    @data = get_json(params[:topic],:offset => params[:offset])
    
    content_type :json
    @data.to_json
  end
end

# Queries the NYT Article API for the given topic
# From MDB's TimesGrapher
def get_json(topic, options = {})
  options = {
    :offset => 0
  }.merge(options)

  base_url = "http://api.nytimes.com/svc/search/v1/"
  api_key = ENV['NYTIMES_API_KEY']
  facets = "desk_facet%3A%5BU.S.+%2F+Politics%5D"
  end_date = Date.today
  begin_date = end_date - 90
  dates = "begin_date=" + begin_date.strftime("%Y%m%d")  + "&end_date=" + end_date.strftime("%Y%m%d")
  query = "article?format=json&query=#{topic}&offset=#{options[:offset]}&#{dates}&fields=title,url,date,geo_facet"
  url = "#{base_url}#{URI.encode(query)}&api-key=#{api_key}"
  puts url
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body

  # convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, then raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end
  
  return result
end

helpers do 

  def reformat_location_hash(results)
    locations_hash = {}

    results.each do |l|
      locations_hash[l.name] = {}
      locations_hash[l.name]['lat'] = l.lat
      locations_hash[l.name]['lng'] = l.lng
    end

    return locations_hash
  end

end

