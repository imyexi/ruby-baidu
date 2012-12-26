#coding:UTF-8
require 'rubygems'
require 'mechanize'
require 'json'
require 'uri'
class Baidu
    BaseUri = 'http://www.baidu.com/s?'
    PerPage = 100

    def initialize
        @a = Mechanize.new {|agent| agent.user_agent_alias = 'Linux Mozilla'}
        @a.idle_timeout = 2
        @a.max_history = 1
        @page = nil
    end

    def suggestions(wd)
        json = @a.get("http://suggestion.baidu.com/su?wd=#{URI.encode(wd)}&cb=callback").body.force_encoding('GBK').encode("UTF-8")
        m = /\[([^\]]*)\]/.match json
        return JSON.parse m[0]
    end

=begin
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
=end

    def popular?(wd)
        return @a.get("http://index.baidu.com/main/word.php?word=#{URI.encode(wd.encode("GBK"))}").body.include?"boxFlash"
    end
    
    def query(wd)
        q = Array.new
        q << "wd=#{wd}"
        q << "rn=#{PerPage}"
        queryStr = q.join("&")
        #uri = URI.encode((BaseUri + queryStr).encode('GBK'))
        uri = URI.encode((BaseUri + queryStr))
        begin
            @page = @a.get uri
            BaiduResult.new(@page)
        rescue Net::HTTP::Persistent::Error
            warn "#{uri}timeout"
            return false
        end
=begin
        query = "#{query}"
        @uri = BaseUri+URI.encode(query.encode('GBK'))
        @page = @a.get @uri
        self.clean
        @number = self.how_many
        @maxpage = (@number / @perpage.to_f).round
        @maxpage =10 if @maxpage>10
        @currpage =0
=end
    end

=begin
    def maxpage
        @maxpage ||= (how_many / PerPage.to_f).round
    end
=end

    #site:xxx.yyy.com
    def how_many_pages(host)
        query("site:#{host}").how_many
    end

    #domain:xxx.yyy.com/path/file.html
    def how_many_links(uri)
        query("domain:\"#{uri}\"").how_many
    end

    #site:xxx.yyy.com inurl:zzz
    def how_many_pages_with(host,string)
        query("site:#{host} inurl:#{string}").how_many
    end

=begin
    private
    def clean
        @page.body.force_encoding('GBK')
        @page.body.encode!('UTF-8',:invalid => :replace, :undef => :replace, :replace => "")
        @page.body.gsub! ("[\U0080-\U2C77]+") #mechanize will be confuzed without removing the few characters
    end
=end
end

class BaiduResult
    def initialize(page)
        raise ArgumentError 'should be Mechanize::Page' unless page.class == Mechanize::Page
        @page = page
    end
    
    def ranks(host=nil)
        @ranks ||= @page.search("//table[@class=\"result\"]").map{|table|@page.search("//table[@id=\"#{table['id']}\"]//span[@class=\"g\"]").first}.map{|rank|URI('http://'+rank.text.strip.split(/\s/).first).host unless rank.nil?}
        if host.nil?
            @ranks
        else
            @ranks.each_with_index.map{|h,i| i if !h.nil? and h==host}.compact
        end
    end
    
    #look up a word and get the rank of a uri with $host
    def rank(host)#on base of ranks
        ranks.each_with_index do |uri,index|
            next if uri.nil?
            return index+1 if uri.split('/')[0].strip == host
            #return index+1 if URI.parse(URI.encode(uri)).host == host
        end
        return nil
    end

    def how_many
        @how_many ||= @page.search("//span[@class='nums']").map{|num|num.content.gsub(/\D/,'').to_i unless num.nil?}.first
    end

    def related_keywords
        @related_keywords ||= @page.search("//div[@id=\"rs\"]//tr//a").map{|keyword| keyword.text}
    end
    
    def next
        @page = BaiduResult.new(Mechanize.new.click(@page.link_with(:text=>/下一页/))) unless @page.link_with(:text=>/下一页/).nil?
    end
end
