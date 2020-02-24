require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, "super_secret2"
end

root = File.expand_path("..", __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get '/' do
  pattern = File.join(data_path, "*")

  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end
# get '/' do
#   # binding.pry
#   if session[:username]  == 'admin' && session[:password]  == 'secret'
#     pattern = File.join(data_path, "*")
#
#     @files = Dir.glob(root + "/data/*").map do |path|
#       File.basename(path)
#     end
#     erb :index
#   else
#     erb :users
#   end
# end

get '/users' do
  erb :users
end

get '/new' do
  erb :new
end

get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/create' do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)
    # create_document(filename)
    File.write(file_path, "")
    session[:message] = "#{filename} has been created."

    redirect '/'
  end
end

post '/:filename' do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

post "/:filename/delete" do
  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if params[:username] == "admin" && params[:password] == "secret"
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session[:password] = nil
  session[:username] = nil
  session[:message] = "You have been signed out."
  redirect '/'
end
