#coding:UTF-8
require './lib/baidu.rb'
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
