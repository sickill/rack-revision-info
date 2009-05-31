module Rack
  class RevisionInfo
    
    def initialize(app, opts={})
      @app = app
      path = opts[:path] or raise ArgumentError, "You must specify directory of your local repository!"
      case detect_type(path)
      when :git
        info = `cd #{path}; LC_ALL=C git log -1 --pretty=medium`
        revision = info[/commit\s([a-z0-9]+)/, 1]
        date = (d = info[/Date:\s+(.+)$/, 1]) && (DateTime.parse(d) rescue nil)
      when :svn
        info = `cd #{path}; LC_ALL=C svn info`
        revision = info[/Revision:\s(\d+)$/, 1]
        date = (d = info[/Last Changed Date:\s([^\(]+)/, 1]) && (DateTime.parse(d.strip) rescue nil)
      else
        revision, date = nil, nil
      end
      @revision_info = "Revision #{revision || 'unknown'}"
      @revision_info << " (#{date.strftime("%Y-%m-%d %H:%M:%S %Z")})" if date
    end

    def call(env)
      status, headers, body = @app.call(env)
      if headers['Content-Type'] == 'text/html'
        body << "\n" << %(<!-- #{@revision_info} -->)
      end
      [status, headers, body]
    end

    protected

    def detect_type(path)
      return :git if ::File.directory?(::File.join(path, ".git"))
      return :svn if ::File.directory?(::File.join(path, ".svn"))
      :unknown
    end

  end
end