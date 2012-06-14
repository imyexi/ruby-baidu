#coding:UTF-8
require '../lib/baidu.rb'
describe "Baidu Query" do
    baidu = Baidu.new
    page = baidu.query '百度'

    it "should return BaiduResult" do
        page.class.should == BaiduResult
    end
    
    it "should return 100,000,000" do
        page.how_many.should == 100000000
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
