#coding:UTF-8
require 'rubygems'
require 'mechanize'
require 'json'
require 'uri'
class Baidu
    attr_accessor :perpage,:pagenumber,:debug
    attr_reader :page,:wd,:data
    BaseUri = 'http://www.baidu.com/s?'
    def initialize
        @a = Mechanize.new {|agent| agent.user_agent_alias = 'Linux Mozilla'}
        @a.idle_timeout = 2
        @a.max_history = 1
        @perpage = 100
        @page = nil
        @debug = false
        @data = Hash.new
        #@baseuri = "http://www.baidu.com/s?rn=#{@perpage}&wd="
    end

    public
    def suggestions(wd)
        json = @a.get("http://suggestion.baidu.com/su?wd=#{URI.encode(wd)}&cb=callback").body.force_encoding('GBK').encode("UTF-8")
        m = /\[([^\]]*)\]/.match json
        return JSON.parse m[0]
    end

    def extend(words,level=3,sleeptime=1)
        level = level.to_i - 1
        words = [words] unless words.respond_to? 'each'
        
        extensions = Array.new
        words.each do |word|
            self.query(word)
            extensions += related_keywords
            extensions += suggestions(word)
            sleep sleeptime
        end
        extensions.uniq!
        return extensions if level < 1
        return extensions + extend(extensions,level)
    end

    def popular?(wd)
        return @a.get("http://index.baidu.com/main/word.php?word=#{URI.encode(wd.encode("GBK"))}").body.include?"boxFlash"
    end
    
    def query(wd)
        @data.clear
        @wd = wd
        @data.clear
        q = Array.new
        q << "wd=#{wd}"
        q << "rn=#{@perpage}"
        queryStr = q.join("&")
        uri = URI.encode((BaseUri + queryStr).encode('GBK'))
        begin 
            @page = @a.get uri
        rescue Net::HTTP::Persistent::Error
            warn "#{uri}timeout"
        end
        clean
        @number = self.how_many
        @maxpage = (@number / @perpage.to_f).round
        @currpage =0
=begin
        query = "#{query}"
        @uri = @baseuri+URI.encode(query.encode('GBK'))
        @page = @a.get @uri
        self.clean
        @number = self.how_many
        @maxpage = (@number / @perpage.to_f).round
        @maxpage =10 if @maxpage>10
        @currpage =0
=end
    end

    #site:xxx.yyy.com
    def how_many_pages(host)
        return @data['how_many']if @data.has_key?'how_many'
        query("site:#{host}")
        return how_many
    end

    #domain:xxx.yyy.com/path/file.html
    def how_many_links(uri)
        return @data['how_many']if @data.has_key?'how_many'
        query("domain:\"#{uri}\"")
        return how_many
    end

    #site:xxx.yyy.com inurl:zzz
    def how_many_pages_with(host,string)
        return @data['how_many']if @data.has_key?'how_many'
        query("site:#{host} inurl:#{string}")
        return how_many
    end
    ########################################################################################################################
    #look up a word and get the rank of a uri with $host
    def rank(host)#on base of ranks
        return @data[:rank][host] if @data.has_key?:rank and @data[:rank].has_key?host
        ranks.each_with_index do |uri,index|
            if URI.parse(URI.encode(uri).host)
                @data << {:rank=>{host=>index+1}}
                return index+1
            end
        end
=begin
        @page.search("//table[@class=\"result\"]").each do |table|
            href = @page.search("//table[@id=\"#{table['id']}\"]//a").first['href']
            begin
                return table['id'] if host==URI.parse(URI.encode(href)).host
            rescue URI::InvalidURIError
                puts "invalid uri:#{href}" if @debug
            end
        end
        return false
=end
    end

    def ranks#(keyword=false)
        return @data[:ranks] if @data.has_key?:ranks
        raise StandardError,'wrong with @page' unless @page.instance_of? Mechanize::Page
        #self.query(keyword) if keyword
        ranks = Array.new
        @page.search("//table[@class=\"result\"]").each do |table|
            ranks << @page.search("//table[@id=\"#{table['id']}\"]//a").first['href']
        end
        @data[:ranks] = ranks
        return ranks
    end

    def related_keywords
        return @data[:realated_keywords] if @data.has_key?:realated_keywords
        raise StandardError,'wrong with @page' unless @page.instance_of? Mechanize::Page
        keywords = Array.new
        div = @page.search("//div[@id=\"rs\"]//tr//a")
        return false if div.nil?
        div.each do |keyword|
            keywords << keyword.text
        end
        @data[:realated_keywords] = keywords
        return keywords
        #m = /href="[^"]+">([^<]+)<\/a>/.match(related.content)
    end

    def how_many
        return @data['how_many'] if @data.has_key?'how_many'
        raise StandardError,'wrong with @page' unless @page.instance_of? Mechanize::Page
        numSpan = @page.search("//span[@class='nums']").first
        return false if numSpan.nil?
        return numSpan.content.gsub(/\D/,'').to_i
        #return false if @page.search("//span[@class='nums']").first.nil?
        #return @page.search("//span[@class='nums']").first.content.gsub(/\D/,'').to_i
    end

    def next
        nextbtn = @page.link_with(:text=>/下一页/)
        return false if (nextbtn.nil? or @currpage >= @maxpage)
        @page = @a.click(nextbtn)
        self.clean
        return true
    end
    private
    def clean
        @page.body.force_encoding('GBK')
        @page.body.encode!('UTF-8',:invalid => :replace, :undef => :replace, :replace => "")
        @page.body.gsub! ("[\U0080-\U2C77]+") #mechanize will be confuzed without removing the few characters
    end
end
