#coding:UTF-8
require '../lib/baidu.rb'
describe Qihoo do
    qihoo = Qihoo.new
    page = qihoo.query '360'
    page2 = page.next
    page3 = page2.next
    it "应返回MbaiduResult的实例" do 
        page.class.should == QihooResult
    end
    it "下一页也应是MbaiduResult的实例" do
        page2.class.should == QihooResult
    end
    it "下一页也应是MbaiduResult的实例" do
        page3.class.should == QihooResult 
    end
    it "360导航域名应该大于1" do
        page.rank('hao.360.cn').should > 1
    end
    it "360首页域名应该在10以内" do
        page.rank('www.360.cn').should < 11
    end
end

describe Mbaidu do
    mbaidu = Mbaidu.new
    page = mbaidu.query '百度'
    page2 = page.next
    page3 = page2.next
    it "应返回MbaiduResult的实例" do 
        page.class.should == MbaiduResult
    end
    it "下一页也应是MbaiduResult的实例" do
        page2.class.should == MbaiduResult
    end
    it "下一页也应是MbaiduResult的实例" do
        page3.class.should == MbaiduResult
    end
    it "百度百科域名应该大于1" do
        page.rank('baike.baidu.com').should > 1
    end
    it "百度无线域名应该在10以内" do
        page.rank('m.baidu.com').should < 11
    end
end

describe Baidu do
    baidu = Baidu.new
    page = baidu.query '百度'

    it "should return BaiduResult" do
        page.class.should == BaiduResult
    end
    
    it "should return 100,000,000" do
        page.how_many.should == 100000000
    end
    it "should return ineter and bigger than 1" do
        page.rank('baike.baidu.com').should > 1
    end
    it "should return integer and less than 11" do
        page.rank('www.baidu.com').should < 11
    end
    
    it "should return BaiduResult" do
        page.next.class.should == BaiduResult
    end
    
    it "should return true" do
        bool = baidu.popular?'百度'
        bool.should == true
    end
    
    it "should return false" do
        bool = baidu.popular?'lavataliuming'
        bool.should == false
    end
    
    it "should return 10 words beginning with the query_word" do
        query_word = '为'
        suggestions = baidu.suggestions(query_word)
        suggestions.size.should == 10
        suggestions.each do |suggestion|
            suggestion[0].should == query_word
        end
    end
    
    it "should return 100,000,000" do
        baidu.how_many_pages('baidu.com').should == 100000000
    end
    
    it "should return 100,000,000" do
        baidu.how_many_links('baidu.com').should == 100000000
    end
    it "should return 100,000,000" do
        baidu.how_many_pages_with('baidu.com','baidu.com').should. == 100000000
    end
end
