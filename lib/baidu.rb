#coding:UTF-8
require 'mechanize'
require 'nokogiri'
require 'json'
require 'addressable/uri'
require 'httparty'

class SearchResult
    def initialize(body,baseuri,pagenumber=nil)
        @body = Nokogiri::HTML body
        @baseuri = baseuri
        # @host = URI(baseuri).host
        if pagenumber.nil?
            @pagenumber = 1
        else
            @pagenumber = pagenumber
        end
    end

    #返回当前页中host满足条件的结果
    def ranks_for(specific_host)
        host_ranks = Hash.new
        ranks.each do |id,line|
            if specific_host.class == Regexp
                host_ranks[id] = line if line['host'] =~ specific_host
            elsif specific_host.class == String
                host_ranks[id] = line if line['host'] == specific_host
            end
        end
        host_ranks
    end
    #return the top rank number from @ranks with the input host
    def rank(host)#on base of ranks
        ranks.each do |id,line|
            id = id.to_i
            if host.class == Regexp
                return id if line['host'] =~ host
            elsif host.class == String
                return id if line['host'] == host
            end
        end
        return nil
    end
end
class Qihoo 
    Host = 'www.so.com'
    #基本查询, 相当于在搜索框直接数据关键词查询
    def query(wd)
        begin
            #用原始路径请求
            uri = URI.encode(URI.join("http://#{Host}/",'s?q='+wd).to_s)
            body = HTTParty.get(uri)
            #如果请求地址被跳转,重新获取当前页的URI
            uri = URI.join("http://#{Host}/",body.request.path).to_s
            return QihooResult.new(body,uri)
        rescue Exception => e
            warn "#{uri} fetch error: #{e.to_s}"
            return false
        end
    end
    #是否收录
    def indexed?(url)
        URI(url)
        query(url).has_result?
    end
end

class QihooResult < SearchResult
    Host = 'www.so.com'

    #返回所有当前页的排名结果
    def ranks
        return @ranks unless @ranks.nil?
        @ranks = Hash.new
        id = (@pagenumber - 1) * 10
        @body.xpath('//li[@class="res-list"]').each do |li|
            a = li.search("h3/a").first
            url = li.search("cite")
            next if a['data-pos'].nil?
            id += 1
            text = a.text.strip
            href = a['href']
            url = url.first.text
            host = Addressable::URI.parse(URI.encode("http://#{url}")).host
            @ranks[id] = {'href'=>"http://so.com#{href}",'text'=>text,'host'=>host}
        end
        @ranks
    end
    #下一页
    def next
        next_href = @body.xpath('//a[@id="snext"]').first['href']
        next_href = URI.join(@baseuri,next_href).to_s
        # next_href = URI.join("http://#{@host}",next_href).to_s
        next_body = HTTParty.get(next_href).body
        return QihooResult.new(next_body,next_href,@pagenumber+1)
        #@page = MbaiduResult.new(Mechanize.new.click(@page.link_with(:text=>/下一页/))) unless @page.link_with(:text=>/下一页/).nil?
    end
    #有结果
    def has_result?
        !@body.xpath('//div[@id="main"]/h3').text().include?'没有找到该URL'
    end
end

class Mbaidu
    BaseUri = 'http://m.baidu.com/s?'
    headers = {
        "User-Agent" => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_2 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8H7 Safari/6533.18.5'
    }
    Options = {:headers => headers}

    #基本查询,相当于从搜索框直接输入关键词查询
    def query(wd)
        queryStr = "word=#{wd}"
        uri = URI.encode((BaseUri + queryStr))
        begin
            res = HTTParty.get(uri,Options)
            MbaiduResult.new(res,uri)
        rescue Exception => e
            warn "#{uri} fetch error: #{e.to_s}"
            return false
        end
    end
end
class MbaiduResult < SearchResult
    def initialize(body,baseuri,pagenumber=nil)
        @body = Nokogiri::HTML body
        @baseuri = baseuri
        if pagenumber.nil?
            @pagenumber = 1
        else
            @pagenumber = pagenumber
        end
    end

    #返回当前页所有查询结果
    def ranks
        #如果已经赋值说明解析过,不需要重新解析,直接返回结果
        return @ranks unless @ranks.nil?
        @ranks = Hash.new
        @body.xpath('//div[@class="result"]').each do |result|
            href,text,host,is_mobile = '','','',false
            a = result.search("a").first
            is_mobile = true unless a.search("img").empty?
            host = result.search('span[@class="site"]').first.text
            href = a['href']
            text = a.text
            id = href.scan(/&order=(\d+)&/)
            if id.empty?
                id = nil
            else
                id = id.first.first.to_i
                id = (@pagenumber-1)*10+id
            end
=begin
            result.children.each do |elem|
                if elem.name == 'a'
                    href = elem['href']
                    id = elem.text.match(/^\d+/).to_s.to_i
                    text = elem.text.sub(/^\d+/,'')
                    text.sub!(/^\u00A0/,'')
                elsif elem['class'] == 'abs'
                    elem.children.each do |elem2|
                        if elem2['class'] == 'site'
                            host = elem2.text
                            break
                        end
                    end
                elsif elem['class'] == 'site'
                    host == elem['href']
                end
            end
=end

            @ranks[id] = {'href'=>href,'text'=>text,'is_mobile'=>is_mobile,'host'=>host.sub(/\u00A0/,'')}
        end
        @ranks
    end
=begin
    #返回当前页中,符合host条件的结果
    def ranks_for(specific_host)
        host_ranks = Hash.new
        ranks.each do |id,line|
            if specific_host.class == Regexp
                host_ranks[id] = line if line['host'] =~ specific_host
            elsif specific_host.class == String
                host_ranks[id] = line if line['host'] == specific_host
            end
        end
        host_ranks
    end
    #return the top rank number from @ranks with the input host
    def rank(host)#on base of ranks
        ranks.each do |id,line|
            id = id.to_i
            if host.class == Regexp
                return id if line['host'] =~ host
            elsif host.class == String
                return id if line['host'] == host
            end
        end
        return nil
    end
=end
    #下一页
    def next
        url = @body.xpath('//a[text()="下一页"]').first['href']
        url = URI.join(@baseuri,url).to_s
        body = HTTParty.get(url)
        return MbaiduResult.new(body,url,@pagenumber+1)
    end

end
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
        json = HTTParty.get("http://suggestion.baidu.com/su?wd=#{URI.encode(wd)}&cb=callback").body.force_encoding('GBK').encode("UTF-8")
        m = /\[([^\]]*)\]/.match json
        return JSON.parse m[0]
    end
    #to find out the real url for something lik 'www.baidu.com/link?url=7yoYGJqjJ4zBBpC8yDF8xDhctimd_UkfF8AVaJRPKduy2ypxVG18aRB5L6D558y3MjT_Ko0nqFgkMoS'
    def url(id)
      a = Mechanize.new
      a.redirect_ok=false
      return a.head("http://www.baidu.com/link?url=#{id}").header['location']
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
    #是否收录
    def indexed?(url)
        query(url).has_result?
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

class BaiduResult < SearchResult
    def initialize(page)
        raise ArgumentError 'should be Mechanize::Page' unless page.class == Mechanize::Page
        @page = page
    end
    
    def ranks
        return @ranks unless @ranks.nil?
        @ranks = Hash.new
        @page.search("//table[@class=\"result\"]").each do |table|
            id = table['id']
            @ranks[id] = Hash.new
            url = @page.search("//table[@id=\"#{table['id']}\"]//span[@class=\"g\"]").first
            a = @page.search("//table[@id=\"#{table['id']}\"]//h3/a")
            @ranks[id]['text'] = a.text
            @ranks[id]['href'] = a.first['href'].sub('http://www.baidu.com/link?url=','').strip
            unless url.nil?
                url = url.text.strip
                @ranks[id]['host'] = Addressable::URI.parse(URI.encode("http://#{url}")).host
            else
                @ranks[id]['host'] = nil
            end
        end
        #@page.search("//table[@class=\"result\"]").map{|table|@page.search("//table[@id=\"#{table['id']}\"]//span[@class=\"g\"]").first}.map{|rank|URI(URI.encode('http://'+rank.text.strip)).host unless rank.nil?}
        @ranks
    end
    
    #return the top rank number from @ranks with the input host
    # def rank(host)#on base of ranks
    #     ranks.each do |id,line|
    #         id = id.to_i
    #         if host.class == Regexp
    #             return id if line['host'] =~ host
    #         elsif host.class == String
    #             return id if line['host'] == host
    #         end
    #     end
    #     return nil
    # end

    def how_many
        @how_many ||= @page.search("//span[@class='nums']").map{|num|num.content.gsub(/\D/,'').to_i unless num.nil?}.first
    end

    def related_keywords
        @related_keywords ||= @page.search("//div[@id=\"rs\"]//tr//a").map{|keyword| keyword.text}
    end
    
    def next
        @page = BaiduResult.new(Mechanize.new.click(@page.link_with(:text=>/下一页/))) unless @page.link_with(:text=>/下一页/).nil?
    end

    def has_result?
        @page.search('//div[@class="nors"]').empty?
    end
    
end