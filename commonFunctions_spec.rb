require 'dotenv/load'
require 'mongo'
require './commonFunctions.rb'

Mongo::Logger.logger.level = Logger::FATAL
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])



RSpec.describe "commonFunctions" do
    it "adds commas" do
        expect(number_with_commas(1000)).to eq("1,000")
        expect(number_with_commas(1000.00)).to eq("1,000.0")
    end


    it "grows population" do
        range = 0.25
        expect(getNewPopulation(100, 0.5)).to eq(100)
        expect(getNewPopulation(100, 1)).to eq((100.0 * (1.0 + (range / 2))).round.to_i)
        expect(getNewPopulation(100, 0)).to eq((100.0 * (1.0 - (range / 2))).round.to_i)
    end


    it "gets new happiness" do
        expect(getNewHappiness(0.5, 0.325)).to be_between(0.499, 0.501)
        expect(getNewHappiness(0.5, 0.4)).to be < (0.5)
        expect(getNewHappiness(0.5, 0.2)).to be > (0.5)
    end

    it "slopeInterpolate works for tax rage" do
        expect(slopeInterpolate(0.325, 0.0, 1.0, 0.0, 1.0, 0.9)).to be_between(0.499, 0.501)
        expect(slopeInterpolate(0.0, 0.0, 1.0, 0.0, 1.0, 0.9)).to eq(0.0)
        expect(slopeInterpolate(1.0, 0.0, 1.0, 0.0, 1.0, 0.9)).to eq(1.0)
    end
end