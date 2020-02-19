require './commonFunctions.rb'


RSpec.describe "commonFunctions" do
    it "adds commas" do
        expect(number_with_commas(1000)).to eq("1,000")
        expect(number_with_commas(1000.00)).to eq("1,000.0")
    end
end