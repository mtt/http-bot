require 'net/http'
require 'net/https'

module HTTPBot

  #Use this to login and access one particular site
  def self.connect(host,options={})
    yield Connection.new(host)
  end
	
  class Connection

    def initialize(host,options={})
      @host = host
      @user_agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1"
      @cookies = []
      @url  = URI.parse(@host)
      @http = Net::HTTP.new(@url.host, @url.port)
      @http.use_ssl = @host =~ /^https/i ? true : false
      
      fetch_cookies
    end
    
    #Do GET first to setup cookies
    def fetch_cookies
      get { |http, response| set_cookies(response) }
    end
    
    def request(url,type='Get')
      url = "/#{url}" unless url =~ /^\//
      @url  = URI.parse(@host)
      @url.path = url
      klass = eval("Net::HTTP::#{type}")
      req = klass.new(@url.path)
      req.add_field('User-Agent',@user_agent)
      res = @http.start do |http| 
        response = http.request(req)
	yield(http,response)
      end
    end
    
    def get(url='',&block)
      request(url,'Get',&block)
    end
    
    def post(url='',&block)
      request(url,'Post',&block)
    end
    
    def set_cookies(response)
      @cookies = []
      response.each_header do |key,val|
        @cookies << val if key =~ /set-cookie/i
      end
    end
    
   end

end