require 'net/http'
require 'net/https'


module HTTPBot

  #Use this to login and access one particular site
  def self.connect(host,options={})
    yield Connection.new(host) if block_given?
  end
	
  class Connection
    attr_reader :response_headers, :response, :redirected_to
    
    def initialize(host,options={})
      @host = host
      @user_agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1"
      @cookies = []
      @url  = URI.parse(@host)
      @http = Net::HTTP.new(@url.host, @url.port)
      @http.set_debug_output $stdout
      @http.use_ssl = @host =~ /^https/i ? true : false
      @response_header = {}
      @response = nil
      @redirected_to = nil
      
      fetch_cookies
    end
    
    #Do GET first to setup cookies
    #Cookies are set on every request
    def fetch_cookies
      get
    end
    
    def request(url,type='Get',form_data={},options={})
      url = "/#{url}" unless url =~ /^\//
      @url  = URI.parse(@host)
      @url.path = url
      klass = eval("Net::HTTP::#{type}")
      req = klass.new(@url.path)
      
      req.add_field('User-Agent',@user_agent)
      @cookies.each { |cookie| req.add_field('Cookie',cookie) }
      
      set_form_data(req,form_data,options)
    
      res = @http.start do |http| 
        @response = response = http.request(req)
        set_response_headers(response)
        set_cookies(response)
        yield(http,response) if block_given?
      end
    end
    
    def get(url='',form_data={},options={},&block)
      request(url,'Get',form_data,options,&block)
    end
    
    def post(url='',form_data={},options={},&block)
      request(url,'Post',form_data,options,&block)
    end
    
    def set_cookies(response)
      @cookies = []
      response.each_header do |key,val|
        @cookies << val if key =~ /set-cookie/i
      end
    end
    
    def set_response_headers(response)
      @response_headers = {}
      response.each_header do |key,val| 
        @response_headers[key] = val 
        @redirected_to = val if key =~ /location/i
      end
    end
    
    def set_form_data(req,form_data={},options={})
      if options[:multipart]
        mp = Multipart::MultipartPost.new
        query, headers = mp.prepare_query(form_data)
        req.body = query
        req.delete("content-type")
        headers.each { |key,val| req.add_field(key,val) }
      else
        req.set_form_data(form_data)
      end
    end
     
    def body
      @response.nil? ? nil : @response.body
    end 
    
   end

end
