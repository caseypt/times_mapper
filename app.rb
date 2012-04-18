require 'rubygems'
require 'sinatra'
require 'compass'
require 'sass'
require 'haml'
require 'json'
require 'net/http'
require 'date'

configure do
  set :haml, {:format => :html5, :escape_html => true}
  set :scss, {:style => :compact, :debug_info => false}
  Compass.add_project_configuration(File.join(Sinatra::Application.root, '/views/config.rb'))
end

get '/stylesheets/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss(:"stylesheets/#{params[:name]}" )
end

get '/' do
  if params[:search]
    @data = get_json(params[:search])
  end

  haml:index
end

get '/test' do
  @data = get_json('romney')
  puts @data
end

def get_json(topic, options = {})
  options = {
    :begin_date => '20120101',
    :end_date => '20120130',
    :offset => 0
  }.merge(options)

  base_url = "http://api.nytimes.com/svc/search/v1/"
  api_key = ENV['NYTIMES_API_KEY']
  query = "article?format=json&query=#{topic}&begin_date=#{options[:begin_date]}&end_date=#{options[:end_date]}&offset=#{options[:offset]}&fields=title,url,date"
  url = "#{base_url}#{URI.encode(query)}&api-key=#{api_key}"
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