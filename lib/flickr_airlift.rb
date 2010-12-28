require 'rubygems'
require 'flickraw'
require 'net/http'

module FlickrAirlift

  def self.download
    begin
      # Setup
      FlickRaw.api_key        = "d4d152785af1b0ea68a5a2d173c75707"
      FlickRaw.shared_secret  = "b9da0b4f99507dd0"
      frob                    = flickr.auth.getFrob
      auth_url                = FlickRaw.auth_url :frob => frob, :perms => 'read'

      # TODO: Use open if it's supported
      puts " "
      puts "Open this url in your process to complete the authication process:"
      puts auth_url
      puts "Press Enter when you are finished."
      STDIN.getc

      # Authentication
      auth  = flickr.auth.getToken :frob => frob
      login = flickr.test.login
      puts "You are now authenticated as #{login.username} with token #{auth.token}"

      # Prompt
      puts "Exactly who's photos would you like to archive?:"
      scraped_user = STDIN.gets
      scraped_user = scraped_user.strip

      # Find
      user_id       = flickr.people.findByUsername(:username => scraped_user).id
      photos        = flickr.photos.search(:user_id => user_id)
      photo_count   = photos.total
      page_count    = photos.pages

      # Downloading
      puts "#{scraped_user} has #{photo_count} pictures"
      puts "* Creating folder named '#{scraped_user}'"
      Dir.mkdir(scraped_user) unless File.directory?(scraped_user)

      (1..page_count.to_i).each do |page_number|
        puts "* PAGE #{page_number} of #{page_count}"
        flickr.photos.search(:user_id => user_id, :page => page_number).each_with_index do |photo, i|
          photo_id     = photo.id
          info         = flickr.photos.getInfo(:photo_id => photo_id)
          download_url = FlickRaw.url_o(info)

          puts "** Downloading #{i+1}: #{photo.title} from #{download_url}"
          File.open(File.join(scraped_user, "#{photo_id}.jpg"), 'w') do |file|
            file.puts Net::HTTP.get_response(URI.parse(download_url)).body
          end

        end
      end

      rescue FlickRaw::FailedResponse => e
        puts e.msg
      end
  end

end