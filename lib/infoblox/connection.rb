module Infoblox
  class Connection
    attr_accessor :adapter, 
                  :adapter_block,
                  :connection, 
                  :host, 
                  :logger, 
                  :password, 
                  :ssl_opts, 
                  :username

    def get(href, params={})
      wrap do
        connection.get(href, params)
      end
    end

    def post(href, body)
      wrap do
        connection.post do |req|
          req.url href
          req.body = body.to_json
        end
      end
    end

    def put(href, body)
      wrap do
        connection.put do |req|
          req.url href
          req.body = body.to_json
        end
      end
    end

    def delete(href)
      wrap do
        connection.delete(href)
      end
    end

    def initialize(opts={})
      self.username = opts[:username]
      self.password = opts[:password]
      self.host     = opts[:host]
      self.logger   = opts[:logger]
      self.ssl_opts = opts[:ssl_opts] 
    end

    def connection
      @connection ||= Faraday.new(:url => self.host, :ssl => {:verify => false}) do |faraday|
        faraday.use Faraday::Response::Logger, logger if logger
        faraday.request :json
        faraday.basic_auth(self.username, self.password)
        faraday.adapter(self.adapter, &self.adapter_block)
      end
    end

    ##
    # The host variable is expected to be a protocol with a host name. 
    # If the host has no protocol, https:// is added before it. 
    #
    def host=(new_host)
      unless new_host =~ /^http(s)?:\/\//
        new_host = "https://#{new_host}"
      end
      @host = new_host
    end

    def adapter
      @adapter ||= :net_http
    end

    private

    def wrap
      yield.tap do |response|
        unless response.status < 300
          raise Exception.new("Error: #{response.status} #{response.body}")
        end
      end
    end
  end
end

